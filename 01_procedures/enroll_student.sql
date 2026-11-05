-- ============================================================
-- enroll_student
-- Concepts: %ROWTYPE record, user-defined record, implicit cursor
-- (SQL%ROWCOUNT), predefined exceptions (NO_DATA_FOUND, DUP_VAL_ON_INDEX),
-- user-defined exceptions, RAISE_APPLICATION_ERROR, OUT parameter.
-- Error codes: -20001 not found, -20002 inactive student,
--              -20003 course full, -20004 already enrolled, -20099 unexpected
-- ============================================================
CREATE OR REPLACE PROCEDURE enroll_student (
  p_student_id    IN  students.student_id%TYPE,
  p_course_id     IN  courses.course_id%TYPE,
  p_semester      IN  enrollments.semester%TYPE,
  p_enrollment_id OUT enrollments.enrollment_id%TYPE
) IS
  -- user-defined record
  TYPE r_course_check IS RECORD (
    course_title courses.title%TYPE,
    capacity     courses.capacity%TYPE,
    seats_taken  PLS_INTEGER
  );
  v_course  r_course_check;
  v_student students%ROWTYPE;                 -- %ROWTYPE record
  v_step    VARCHAR2(20);
  v_rows    PLS_INTEGER;

  e_student_inactive EXCEPTION;               -- user-defined exceptions
  e_course_full      EXCEPTION;
BEGIN
  v_step := 'STUDENT';
  SELECT * INTO v_student FROM students WHERE student_id = p_student_id;
  IF v_student.status <> 'ACTIVE' THEN
    RAISE e_student_inactive;
  END IF;

  v_step := 'COURSE';
  SELECT c.title, c.capacity,
         (SELECT COUNT(*) FROM enrollments e
           WHERE e.course_id = c.course_id AND e.semester = p_semester)
    INTO v_course.course_title, v_course.capacity, v_course.seats_taken
    FROM courses c
   WHERE c.course_id = p_course_id;

  IF v_course.seats_taken >= v_course.capacity THEN
    RAISE e_course_full;
  END IF;

  INSERT INTO enrollments (student_id, course_id, semester)
  VALUES (p_student_id, p_course_id, p_semester)
  RETURNING enrollment_id INTO p_enrollment_id;

  v_rows := SQL%ROWCOUNT;                     -- implicit cursor attribute
  DBMS_OUTPUT.PUT_LINE('Enrolled ' || v_student.full_name || ' in ' ||
                       v_course.course_title || ' (' || p_semester || '). Rows inserted: ' ||
                       v_rows || ', enrollment_id=' || p_enrollment_id);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20001, v_step || ' not found (student=' || p_student_id ||
                                    ', course=' || p_course_id || ')');
  WHEN e_student_inactive THEN
    RAISE_APPLICATION_ERROR(-20002, 'Student ' || p_student_id || ' is ' || v_student.status ||
                                    ' and cannot enroll');
  WHEN e_course_full THEN
    RAISE_APPLICATION_ERROR(-20003, 'Course ' || p_course_id || ' is full (' ||
                                    v_course.seats_taken || '/' || v_course.capacity || ')');
  WHEN DUP_VAL_ON_INDEX THEN
    RAISE_APPLICATION_ERROR(-20004, 'Student ' || p_student_id || ' is already enrolled in ' ||
                                    p_course_id || ' for ' || p_semester);
  WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20099, 'enroll_student failed: ' || SQLERRM);
END enroll_student;
/
SHOW ERRORS
