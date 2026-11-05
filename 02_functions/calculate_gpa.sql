-- ============================================================
-- calculate_gpa: credit-weighted GPA (A=4, B=3, C=2, D=1, F=0).
-- Uses a cursor FOR loop and a %ROWTYPE-style record from the loop.
-- Returns NULL when the student has no graded courses (a GPA of 0
-- would be misleading). Error -20021 if the student does not exist.
-- ============================================================
CREATE OR REPLACE FUNCTION calculate_gpa (p_student_id IN students.student_id%TYPE)
  RETURN NUMBER
IS
  v_name    students.full_name%TYPE;
  v_points  NUMBER := 0;
  v_credits NUMBER := 0;
BEGIN
  SELECT full_name INTO v_name FROM students WHERE student_id = p_student_id;

  FOR r IN (SELECT c.credits, e.grade_letter
              FROM enrollments e
              JOIN courses c ON c.course_id = e.course_id
             WHERE e.student_id = p_student_id
               AND e.grade_letter IS NOT NULL) LOOP
    v_credits := v_credits + r.credits;
    v_points  := v_points + r.credits *
                 CASE r.grade_letter
                   WHEN 'A' THEN 4 WHEN 'B' THEN 3 WHEN 'C' THEN 2
                   WHEN 'D' THEN 1 ELSE 0
                 END;
  END LOOP;

  IF v_credits = 0 THEN
    RETURN NULL;
  END IF;
  RETURN ROUND(v_points / v_credits, 2);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20021, 'Student ' || p_student_id || ' not found');
END calculate_gpa;
/
SHOW ERRORS
