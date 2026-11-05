-- ============================================================
-- bulk_enroll_students
-- Concepts: nested-table collection as IN parameter (t_num_list),
-- FORALL ... INSERT with SAVE EXCEPTIONS, SQL%BULK_EXCEPTIONS,
-- ORA-24381 handling. Valid rows are inserted; bad rows (duplicates,
-- unknown student -> FK violation) are reported, not hidden.
-- Error codes: -20060 empty list, -20061 course not found, -20099 unexpected
-- ============================================================
CREATE OR REPLACE PROCEDURE bulk_enroll_students (
  p_course_id   IN  courses.course_id%TYPE,
  p_semester    IN  enrollments.semester%TYPE,
  p_student_ids IN  t_num_list,
  p_success     OUT PLS_INTEGER,
  p_failed      OUT PLS_INTEGER
) IS
  v_dummy courses.course_id%TYPE;
  e_empty_list  EXCEPTION;
  e_bulk_errors EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_bulk_errors, -24381);
BEGIN
  IF p_student_ids IS NULL OR p_student_ids.COUNT = 0 THEN
    RAISE e_empty_list;
  END IF;

  SELECT course_id INTO v_dummy FROM courses WHERE course_id = p_course_id;  -- NO_DATA_FOUND if missing

  FORALL i IN 1 .. p_student_ids.COUNT SAVE EXCEPTIONS
    INSERT INTO enrollments (student_id, course_id, semester)
    VALUES (p_student_ids(i), p_course_id, p_semester);

  p_success := p_student_ids.COUNT;
  p_failed  := 0;
  DBMS_OUTPUT.PUT_LINE('All ' || p_success || ' students enrolled in ' || p_course_id);
EXCEPTION
  WHEN e_empty_list THEN
    RAISE_APPLICATION_ERROR(-20060, 'Student list is empty');
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20061, 'Course ' || p_course_id || ' not found');
  WHEN e_bulk_errors THEN
    -- handled outcome: report each failed row, keep the successful ones
    p_failed  := SQL%BULK_EXCEPTIONS.COUNT;
    p_success := p_student_ids.COUNT - p_failed;
    DBMS_OUTPUT.PUT_LINE('Bulk enroll finished: ' || p_success || ' succeeded, ' || p_failed || ' failed');
    FOR j IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
      DBMS_OUTPUT.PUT_LINE('  student_id=' ||
                           p_student_ids(SQL%BULK_EXCEPTIONS(j).ERROR_INDEX) || ' -> ORA-' ||
                           LPAD(SQL%BULK_EXCEPTIONS(j).ERROR_CODE, 5, '0') || ': ' ||
                           SQLERRM(-SQL%BULK_EXCEPTIONS(j).ERROR_CODE));
    END LOOP;
  WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20099, 'bulk_enroll_students failed: ' || SQLERRM);
END bulk_enroll_students;
/
SHOW ERRORS
