-- ============================================================
-- get_seats_left: remaining seats in a course for a semester.
-- Error -20022 if the course does not exist.
-- ============================================================
CREATE OR REPLACE FUNCTION get_seats_left (
  p_course_id IN courses.course_id%TYPE,
  p_semester  IN enrollments.semester%TYPE
) RETURN NUMBER
IS
  v_capacity courses.capacity%TYPE;
  v_taken    PLS_INTEGER;
BEGIN
  SELECT capacity INTO v_capacity FROM courses WHERE course_id = p_course_id;

  SELECT COUNT(*) INTO v_taken
    FROM enrollments
   WHERE course_id = p_course_id AND semester = p_semester;

  RETURN GREATEST(v_capacity - v_taken, 0);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20022, 'Course ' || p_course_id || ' not found');
END get_seats_left;
/
SHOW ERRORS
