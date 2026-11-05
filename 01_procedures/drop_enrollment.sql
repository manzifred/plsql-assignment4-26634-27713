-- ============================================================
-- drop_enrollment
-- Concepts: implicit cursor with DELETE (SQL%ROWCOUNT / SQL%NOTFOUND),
-- user-defined exception, RAISE_APPLICATION_ERROR.
-- Only un-graded enrollments may be dropped.
-- Error codes: -20030 not found, -20031 already graded, -20099 unexpected
-- ============================================================
CREATE OR REPLACE PROCEDURE drop_enrollment (
  p_enrollment_id IN  enrollments.enrollment_id%TYPE,
  p_rows_deleted  OUT PLS_INTEGER
) IS
  v_exists PLS_INTEGER;
  e_already_graded EXCEPTION;
  e_not_found      EXCEPTION;
BEGIN
  DELETE FROM enrollments
   WHERE enrollment_id = p_enrollment_id
     AND score IS NULL;

  p_rows_deleted := SQL%ROWCOUNT;

  IF SQL%NOTFOUND THEN
    -- find out WHY nothing was deleted, so the message is accurate
    SELECT COUNT(*) INTO v_exists FROM enrollments WHERE enrollment_id = p_enrollment_id;
    IF v_exists = 0 THEN
      RAISE e_not_found;
    ELSE
      RAISE e_already_graded;
    END IF;
  END IF;

  DBMS_OUTPUT.PUT_LINE('Dropped enrollment ' || p_enrollment_id || ' (' || p_rows_deleted || ' row deleted)');
EXCEPTION
  WHEN e_not_found THEN
    RAISE_APPLICATION_ERROR(-20030, 'Enrollment ' || p_enrollment_id || ' does not exist');
  WHEN e_already_graded THEN
    RAISE_APPLICATION_ERROR(-20031, 'Enrollment ' || p_enrollment_id || ' already has a score and cannot be dropped');
  WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20099, 'drop_enrollment failed: ' || SQLERRM);
END drop_enrollment;
/
SHOW ERRORS
