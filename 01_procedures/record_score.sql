-- ============================================================
-- record_score
-- Concepts: %ROWTYPE, implicit cursor with UPDATE and INSERT
-- (SQL%FOUND, SQL%NOTFOUND, SQL%ROWCOUNT), user-defined exception,
-- NO_DATA_FOUND, RAISE_APPLICATION_ERROR, OUT parameter.
-- Error codes: -20010 invalid score, -20011 enrollment not found, -20099 unexpected
-- ============================================================
CREATE OR REPLACE PROCEDURE record_score (
  p_enrollment_id IN  enrollments.enrollment_id%TYPE,
  p_score         IN  NUMBER,
  p_grade_letter  OUT VARCHAR2
) IS
  v_old  enrollments%ROWTYPE;
  v_rows PLS_INTEGER;
  e_invalid_score EXCEPTION;
BEGIN
  IF p_score IS NULL OR p_score NOT BETWEEN 0 AND 100 THEN
    RAISE e_invalid_score;
  END IF;

  SELECT * INTO v_old FROM enrollments WHERE enrollment_id = p_enrollment_id;

  p_grade_letter := CASE
                      WHEN p_score >= 80 THEN 'A'
                      WHEN p_score >= 70 THEN 'B'
                      WHEN p_score >= 60 THEN 'C'
                      WHEN p_score >= 50 THEN 'D'
                      ELSE 'F'
                    END;

  UPDATE enrollments
     SET score = p_score, grade_letter = p_grade_letter
   WHERE enrollment_id = p_enrollment_id;

  v_rows := SQL%ROWCOUNT;
  IF SQL%FOUND THEN
    DBMS_OUTPUT.PUT_LINE('Updated ' || v_rows || ' row. Old score=' ||
                         NVL(TO_CHAR(v_old.score), 'none') || ', new score=' || p_score ||
                         ', grade=' || p_grade_letter);
    INSERT INTO grade_audit (enrollment_id, old_score, new_score)
    VALUES (p_enrollment_id, v_old.score, p_score);
  ELSIF SQL%NOTFOUND THEN                      -- defensive: row vanished after SELECT
    RAISE_APPLICATION_ERROR(-20011, 'Enrollment ' || p_enrollment_id || ' was not updated');
  END IF;
EXCEPTION
  WHEN e_invalid_score THEN
    RAISE_APPLICATION_ERROR(-20010, 'Score must be between 0 and 100 (received ' ||
                                    NVL(TO_CHAR(p_score), 'NULL') || ')');
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20011, 'Enrollment ' || p_enrollment_id || ' not found');
  WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20099, 'record_score failed: ' || SQLERRM);
END record_score;
/
SHOW ERRORS
