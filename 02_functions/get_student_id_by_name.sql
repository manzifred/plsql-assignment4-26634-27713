-- ============================================================
-- get_student_id_by_name: looks a student up by exact (case-insensitive) name.
-- Demonstrates NO_DATA_FOUND and TOO_MANY_ROWS: names are not unique,
-- so ambiguity is reported instead of silently picking one student.
-- Errors: -20023 not found, -20024 more than one student with that name
-- ============================================================
CREATE OR REPLACE FUNCTION get_student_id_by_name (p_name IN VARCHAR2)
  RETURN NUMBER
IS
  v_id students.student_id%TYPE;
BEGIN
  SELECT student_id INTO v_id
    FROM students
   WHERE UPPER(full_name) = UPPER(TRIM(p_name));
  RETURN v_id;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20023, 'No student named "' || p_name || '"');
  WHEN TOO_MANY_ROWS THEN
    RAISE_APPLICATION_ERROR(-20024, 'More than one student named "' || p_name ||
                                    '"; look up by student_id or email instead');
END get_student_id_by_name;
/
SHOW ERRORS
