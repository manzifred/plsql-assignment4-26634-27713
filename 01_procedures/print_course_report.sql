-- ============================================================
-- print_course_report
-- Concepts: explicit parameterised cursor with OPEN / FETCH / CLOSE,
-- user-defined record, cursor FOR loop, cursor attributes
-- (%NOTFOUND, %ROWCOUNT, %ISOPEN), NO_DATA_FOUND.
-- Error codes: -20040 course not found, -20099 unexpected
-- ============================================================
CREATE OR REPLACE PROCEDURE print_course_report (
  p_course_id IN courses.course_id%TYPE,
  p_semester  IN enrollments.semester%TYPE
) IS
  CURSOR c_roster (cp_course VARCHAR2, cp_sem VARCHAR2) IS
    SELECT s.student_id, s.full_name, e.score, e.grade_letter
      FROM enrollments e
      JOIN students s ON s.student_id = e.student_id
     WHERE e.course_id = cp_course AND e.semester = cp_sem
     ORDER BY s.full_name;

  TYPE r_line IS RECORD (                      -- user-defined record
    student_id   students.student_id%TYPE,
    full_name    students.full_name%TYPE,
    score        enrollments.score%TYPE,
    grade_letter enrollments.grade_letter%TYPE
  );
  v_line  r_line;
  v_title courses.title%TYPE;
  v_count PLS_INTEGER := 0;
BEGIN
  SELECT title INTO v_title FROM courses WHERE course_id = p_course_id;

  DBMS_OUTPUT.PUT_LINE('=== ' || p_course_id || ' - ' || v_title || ' (' || p_semester || ') ===');

  OPEN c_roster(p_course_id, p_semester);
  LOOP
    FETCH c_roster INTO v_line;
    EXIT WHEN c_roster%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE(RPAD(v_line.student_id, 4) || RPAD(v_line.full_name, 25) ||
                         RPAD(NVL(TO_CHAR(v_line.score), '-'), 8) ||
                         NVL(v_line.grade_letter, '-'));
  END LOOP;
  v_count := c_roster%ROWCOUNT;
  CLOSE c_roster;

  IF v_count = 0 THEN
    DBMS_OUTPUT.PUT_LINE('No students enrolled.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('Total enrolled: ' || v_count);
    -- cursor FOR loop: grade distribution
    FOR g IN (SELECT NVL(grade_letter, 'UNGRADED') AS grd, COUNT(*) AS cnt
                FROM enrollments
               WHERE course_id = p_course_id AND semester = p_semester
               GROUP BY NVL(grade_letter, 'UNGRADED')
               ORDER BY 1) LOOP
      DBMS_OUTPUT.PUT_LINE('  ' || RPAD(g.grd, 10) || g.cnt);
    END LOOP;
  END IF;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    IF c_roster%ISOPEN THEN CLOSE c_roster; END IF;
    RAISE_APPLICATION_ERROR(-20040, 'Course ' || p_course_id || ' not found');
  WHEN OTHERS THEN
    IF c_roster%ISOPEN THEN CLOSE c_roster; END IF;
    RAISE_APPLICATION_ERROR(-20099, 'print_course_report failed: ' || SQLERRM);
END print_course_report;
/
SHOW ERRORS
