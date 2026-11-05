-- ============================================================
-- compare_bulk_vs_row
-- Concepts: row-by-row DML vs BULK COLLECT/FORALL, nested table collection,
-- performance measurement. Uses an AUTONOMOUS transaction and rolls back,
-- so it never touches the caller's transaction or the real tables.
-- Error code: -20070 invalid row count, -20099 unexpected
-- ============================================================
CREATE OR REPLACE PROCEDURE compare_bulk_vs_row (
  p_rows IN PLS_INTEGER DEFAULT 20000
) IS
  PRAGMA AUTONOMOUS_TRANSACTION;
  TYPE t_ids  IS TABLE OF NUMBER;
  TYPE t_vals IS TABLE OF VARCHAR2(50);
  l_ids  t_ids  := t_ids();
  l_vals t_vals := t_vals();
  v_start   PLS_INTEGER;
  v_row_cs  PLS_INTEGER;
  v_bulk_cs PLS_INTEGER;
  v_count   PLS_INTEGER;
  e_bad_rows EXCEPTION;
BEGIN
  IF p_rows IS NULL OR p_rows < 1 THEN
    RAISE e_bad_rows;
  END IF;

  -- 1) row-by-row: one context switch PL/SQL -> SQL per row
  v_start := DBMS_UTILITY.GET_TIME;
  FOR i IN 1 .. p_rows LOOP
    INSERT INTO perf_demo (id, val) VALUES (i, 'row_' || i);
  END LOOP;
  v_row_cs := DBMS_UTILITY.GET_TIME - v_start;
  ROLLBACK;

  -- 2) bulk: build collections, then ONE FORALL statement
  l_ids.EXTEND(p_rows);
  l_vals.EXTEND(p_rows);
  FOR i IN 1 .. p_rows LOOP
    l_ids(i)  := i;
    l_vals(i) := 'bulk_' || i;
  END LOOP;

  v_start := DBMS_UTILITY.GET_TIME;
  FORALL i IN 1 .. l_ids.COUNT
    INSERT INTO perf_demo (id, val) VALUES (l_ids(i), l_vals(i));
  v_bulk_cs := DBMS_UTILITY.GET_TIME - v_start;
  v_count := SQL%ROWCOUNT;
  ROLLBACK;

  DBMS_OUTPUT.PUT_LINE('Rows inserted per method : ' || v_count);
  DBMS_OUTPUT.PUT_LINE('Row-by-row time (centisec): ' || v_row_cs);
  DBMS_OUTPUT.PUT_LINE('FORALL time     (centisec): ' || v_bulk_cs);
  IF v_bulk_cs > 0 THEN
    DBMS_OUTPUT.PUT_LINE('FORALL was about ' || ROUND(v_row_cs / v_bulk_cs, 1) || 'x faster');
  ELSE
    DBMS_OUTPUT.PUT_LINE('FORALL finished in under 1 centisecond - increase p_rows to compare');
  END IF;
EXCEPTION
  WHEN e_bad_rows THEN
    ROLLBACK;
    RAISE_APPLICATION_ERROR(-20070, 'p_rows must be a positive number');
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE_APPLICATION_ERROR(-20099, 'compare_bulk_vs_row failed: ' || SQLERRM);
END compare_bulk_vs_row;
/
SHOW ERRORS
