-- ============================================================
-- test_success_cases.sql  (run after schema, data, procedures, functions)
-- Take one screenshot per test: screenshots/<test_name>_output.png
-- ============================================================
SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 150

PROMPT ===== TEST 1: enroll_student (implicit cursor, records) =====
DECLARE
  v_id enrollments.enrollment_id%TYPE;
BEGIN
  enroll_student(4, 'INSY8312', '2026A', v_id);
  DBMS_OUTPUT.PUT_LINE('OUT enrollment_id = ' || v_id);
END;
/

PROMPT ===== TEST 2: bulk_grade_course (BULK COLLECT + FORALL) =====
DECLARE
  v_graded PLS_INTEGER;
BEGIN
  bulk_grade_course('INSY8311', '2026A', v_graded);
  bulk_grade_course('INSY8312', '2026A', v_graded);
  bulk_grade_course('MATH101',  '2026A', v_graded);
  bulk_grade_course('INSY8313', '2026A', v_graded);
  bulk_grade_course('ENGL101',  '2026A', v_graded);
  DBMS_OUTPUT.PUT_LINE('Last call graded = ' || v_graded);
END;
/

PROMPT ===== TEST 3: record_score (UPDATE, SQL%FOUND, audit) =====
DECLARE
  v_enr_id enrollments.enrollment_id%TYPE;
  v_grade  VARCHAR2(1);
BEGIN
  SELECT enrollment_id INTO v_enr_id
    FROM enrollments
   WHERE student_id = 3 AND course_id = 'INSY8312' AND semester = '2026A';
  record_score(v_enr_id, 73.5, v_grade);
  DBMS_OUTPUT.PUT_LINE('OUT grade = ' || v_grade);
END;
/
SELECT audit_id, enrollment_id, old_score, new_score, changed_by FROM grade_audit;

PROMPT ===== TEST 4: print_course_report (explicit cursor + cursor FOR loop) =====
BEGIN
  print_course_report('INSY8311', '2026A');
  print_course_report('MATH101',  '2026A');
END;
/

PROMPT ===== TEST 5: drop_enrollment (implicit DELETE, SQL%ROWCOUNT) =====
DECLARE
  v_enr_id enrollments.enrollment_id%TYPE;
  v_rows   PLS_INTEGER;
BEGIN
  SELECT enrollment_id INTO v_enr_id
    FROM enrollments
   WHERE student_id = 5 AND course_id = 'INSY8313' AND semester = '2026A';
  drop_enrollment(v_enr_id, v_rows);
  DBMS_OUTPUT.PUT_LINE('OUT rows deleted = ' || v_rows);
END;
/

PROMPT ===== TEST 6: bulk_enroll_students (FORALL INSERT, all valid) =====
DECLARE
  v_ok PLS_INTEGER; v_bad PLS_INTEGER;
BEGIN
  bulk_enroll_students('ENGL101', '2026A', t_num_list(1, 2, 3, 4), v_ok, v_bad);
  DBMS_OUTPUT.PUT_LINE('success=' || v_ok || ', failed=' || v_bad);
END;
/

PROMPT ===== TEST 7: functions called from SQL and PL/SQL =====
SELECT student_id, full_name, calculate_gpa(student_id) AS gpa
  FROM students
 ORDER BY student_id;

SELECT score, get_letter_grade(score) AS letter
  FROM enrollments
 WHERE score IS NOT NULL
 ORDER BY score;

BEGIN
  DBMS_OUTPUT.PUT_LINE('Seats left in INSY8312: ' || get_seats_left('INSY8312', '2026A'));
  DBMS_OUTPUT.PUT_LINE('Seats left in INSY8311: ' || get_seats_left('INSY8311', '2026A'));
  DBMS_OUTPUT.PUT_LINE('ID of Aline Uwase     : ' || get_student_id_by_name('aline uwase'));
  DBMS_OUTPUT.PUT_LINE('GPA of student 1      : ' || calculate_gpa(1));
END;
/

PROMPT ===== TEST 8: performance - row-by-row vs FORALL =====
BEGIN
  compare_bulk_vs_row(50000);
END;
/

PROMPT ===== TEST 9: VARRAY - t_score_varray direct usage =====
-- Demonstrates the VARRAY type defined in 00_schema/01_create_tables.sql
DECLARE
  v_scores  t_score_varray := t_score_varray(85, 72, 55, 90, 64, 48, 78, 66, 81, 73.5);
  v_total   NUMBER := 0;
  v_count   NUMBER := 0;
  v_letter  VARCHAR2(1);
BEGIN
  DBMS_OUTPUT.PUT_LINE('--- VARRAY score summary (t_score_varray, max 100 elements) ---');
  FOR i IN 1 .. v_scores.COUNT LOOP
    v_letter := get_letter_grade(v_scores(i));
    v_total  := v_total + v_scores(i);
    v_count  := v_count + 1;
    DBMS_OUTPUT.PUT_LINE('  [' || i || '] score=' || v_scores(i) || '  grade=' || v_letter);
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('Average score : ' || ROUND(v_total / v_count, 2));
  DBMS_OUTPUT.PUT_LINE('VARRAY limit  : ' || v_scores.LIMIT);
  DBMS_OUTPUT.PUT_LINE('VARRAY count  : ' || v_scores.COUNT);
END;
/

ROLLBACK;  -- leave data in its original state for the error tests
