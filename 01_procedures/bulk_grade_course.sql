-- ============================================================
-- bulk_grade_course
-- Concepts: associative arrays, BULK COLLECT, FORALL ... UPDATE with
-- SAVE EXCEPTIONS, SQL%BULK_ROWCOUNT, bulk DML error handling (ORA-24381).
-- Assigns letter grades to every scored enrollment of a course in ONE
-- round trip to the SQL engine instead of one UPDATE per row.
-- Error codes: -20050 nothing to grade, -20051 some rows failed, -20099 unexpected
-- ============================================================
CREATE OR REPLACE PROCEDURE bulk_grade_course (
  p_course_id IN  courses.course_id%TYPE,
  p_semester  IN  enrollments.semester%TYPE,
  p_graded    OUT PLS_INTEGER
) IS
  TYPE t_id_tab     IS TABLE OF enrollments.enrollment_id%TYPE INDEX BY PLS_INTEGER;
  TYPE t_score_tab  IS TABLE OF enrollments.score%TYPE         INDEX BY PLS_INTEGER;
  TYPE t_letter_tab IS TABLE OF enrollments.grade_letter%TYPE  INDEX BY PLS_INTEGER;

  l_ids     t_id_tab;
  l_scores  t_score_tab;
  l_letters t_letter_tab;

  e_nothing_to_grade EXCEPTION;
  e_bulk_errors      EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_bulk_errors, -24381);
BEGIN
  SELECT enrollment_id, score
    BULK COLLECT INTO l_ids, l_scores
    FROM enrollments
   WHERE course_id = p_course_id
     AND semester  = p_semester
     AND score IS NOT NULL;

  IF l_ids.COUNT = 0 THEN
    RAISE e_nothing_to_grade;
  END IF;

  FOR i IN 1 .. l_ids.COUNT LOOP
    l_letters(i) := CASE
                      WHEN l_scores(i) >= 80 THEN 'A'
                      WHEN l_scores(i) >= 70 THEN 'B'
                      WHEN l_scores(i) >= 60 THEN 'C'
                      WHEN l_scores(i) >= 50 THEN 'D'
                      ELSE 'F'
                    END;
  END LOOP;

  FORALL i IN 1 .. l_ids.COUNT SAVE EXCEPTIONS
    UPDATE enrollments
       SET grade_letter = l_letters(i)
     WHERE enrollment_id = l_ids(i);

  p_graded := l_ids.COUNT;
  DBMS_OUTPUT.PUT_LINE('Graded ' || p_graded || ' enrollments for ' || p_course_id ||
                       ' (' || p_semester || ') using BULK COLLECT + FORALL');
EXCEPTION
  WHEN e_nothing_to_grade THEN
    RAISE_APPLICATION_ERROR(-20050, 'No scored enrollments found for ' || p_course_id ||
                                    ' in ' || p_semester);
  WHEN e_bulk_errors THEN
    p_graded := l_ids.COUNT - SQL%BULK_EXCEPTIONS.COUNT;
    FOR j IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
      DBMS_OUTPUT.PUT_LINE('Failed enrollment_id=' ||
                           l_ids(SQL%BULK_EXCEPTIONS(j).ERROR_INDEX) || ': ' ||
                           SQLERRM(-SQL%BULK_EXCEPTIONS(j).ERROR_CODE));
    END LOOP;
    RAISE_APPLICATION_ERROR(-20051, SQL%BULK_EXCEPTIONS.COUNT || ' row(s) could not be graded; ' ||
                                    p_graded || ' succeeded. Caller decides COMMIT or ROLLBACK.');
  WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20099, 'bulk_grade_course failed: ' || SQLERRM);
END bulk_grade_course;
/
SHOW ERRORS
