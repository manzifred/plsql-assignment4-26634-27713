-- ============================================================
-- test_error_cases.sql
-- Every block EXPECTS an error and prints the code/message it received.
-- Run on freshly loaded sample data (or after test_success_cases, which ends with ROLLBACK).
-- ============================================================
SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 150

PROMPT ===== E1: enroll_student - unknown student (-20001, NO_DATA_FOUND) =====
DECLARE v_id NUMBER;
BEGIN enroll_student(999, 'INSY8312', '2026A', v_id);
EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Caught: ' || SQLERRM);
END;
/

PROMPT ===== E2: enroll_student - unknown course (-20001) =====
DECLARE v_id NUMBER;
BEGIN enroll_student(4, 'NOPE999', '2026A', v_id);
EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Caught: ' || SQLERRM);
END;
/

PROMPT ===== E3: enroll_student - suspended student (-20002, user-defined) =====
DECLARE v_id NUMBER;
BEGIN enroll_student(9, 'INSY8312', '2026A', v_id);
EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Caught: ' || SQLERRM);
END;
/

PROMPT ===== E4: enroll_student - course full (-20003, user-defined) =====
DECLARE v_id NUMBER;
BEGIN enroll_student(4, 'INSY8311', '2026A', v_id);
EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Caught: ' || SQLERRM);
END;
/

PROMPT ===== E5: enroll_student - duplicate (-20004, DUP_VAL_ON_INDEX) =====
DECLARE v_id NUMBER;
BEGIN enroll_student(1, 'INSY8312', '2026A', v_id);
EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Caught: ' || SQLERRM);
END;
/

PROMPT ===== E6: record_score - invalid score (-20010) =====
DECLARE v_g VARCHAR2(1);
BEGIN record_score(1, 150, v_g);
EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Caught: ' || SQLERRM);
END;
/

PROMPT ===== E7: record_score - enrollment not found (-20011) =====
DECLARE v_g VARCHAR2(1);
BEGIN record_score(99999, 70, v_g);
EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Caught: ' || SQLERRM);
END;
/

PROMPT ===== E8: drop_enrollment - not found (-20030, SQL%NOTFOUND) =====
DECLARE v_r PLS_INTEGER;
BEGIN drop_enrollment(99999, v_r);
EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Caught: ' || SQLERRM);
END;
/

PROMPT ===== E9: drop_enrollment - already graded (-20031) =====
DECLARE v_r PLS_INTEGER;
BEGIN drop_enrollment(1, v_r);
EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Caught: ' || SQLERRM);
END;
/

PROMPT ===== E10: print_course_report - unknown course (-20040) =====
BEGIN print_course_report('NOPE999', '2026A');
EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Caught: ' || SQLERRM);
END;
/

PROMPT ===== E11: bulk_grade_course - nothing to grade (-20050) =====
DECLARE v_g PLS_INTEGER;
BEGIN bulk_grade_course('INSY8311', '1999Z', v_g);
EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Caught: ' || SQLERRM);
END;
/

PROMPT ===== E12: bulk_enroll_students - SAVE EXCEPTIONS (duplicate + unknown student) =====
DECLARE v_ok PLS_INTEGER; v_bad PLS_INTEGER;
BEGIN
  -- 1 and 2 are already in INSY8312 (unique violation), 888 does not exist (FK violation),
  -- 5 and 6 are valid.
  bulk_enroll_students('INSY8312', '2026A', t_num_list(1, 5, 888, 2, 6), v_ok, v_bad);
  DBMS_OUTPUT.PUT_LINE('success=' || v_ok || ', failed=' || v_bad);
EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Caught: ' || SQLERRM);
END;
/
ROLLBACK;

PROMPT ===== E13: bulk_enroll_students - empty list (-20060) and bad course (-20061) =====
DECLARE v_ok PLS_INTEGER; v_bad PLS_INTEGER;
BEGIN bulk_enroll_students('INSY8312', '2026A', t_num_list(), v_ok, v_bad);
EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Caught: ' || SQLERRM);
END;
/
DECLARE v_ok PLS_INTEGER; v_bad PLS_INTEGER;
BEGIN bulk_enroll_students('NOPE999', '2026A', t_num_list(1), v_ok, v_bad);
EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Caught: ' || SQLERRM);
END;
/

PROMPT ===== E14: compare_bulk_vs_row - invalid input (-20070) =====
BEGIN compare_bulk_vs_row(0);
EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Caught: ' || SQLERRM);
END;
/

PROMPT ===== E15: functions - error handling =====
BEGIN
  BEGIN DBMS_OUTPUT.PUT_LINE(get_letter_grade(120));
  EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('get_letter_grade -> ' || SQLERRM); END;

  BEGIN DBMS_OUTPUT.PUT_LINE(calculate_gpa(999));
  EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('calculate_gpa -> ' || SQLERRM); END;

  BEGIN DBMS_OUTPUT.PUT_LINE(get_seats_left('NOPE999', '2026A'));
  EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('get_seats_left -> ' || SQLERRM); END;

  BEGIN DBMS_OUTPUT.PUT_LINE(get_student_id_by_name('Nobody Here'));
  EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('get_student_id_by_name (NO_DATA_FOUND) -> ' || SQLERRM); END;

  BEGIN DBMS_OUTPUT.PUT_LINE(get_student_id_by_name('Eric Mugisha'));
  EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('get_student_id_by_name (TOO_MANY_ROWS) -> ' || SQLERRM); END;
END;
/
