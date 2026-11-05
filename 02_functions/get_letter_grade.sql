-- ============================================================
-- get_letter_grade: converts a numeric score into A/B/C/D/F.
-- NULL score -> NULL (not graded yet). Out-of-range -> error (-20020),
-- never a misleading letter.
-- ============================================================
CREATE OR REPLACE FUNCTION get_letter_grade (p_score IN NUMBER)
  RETURN VARCHAR2
  DETERMINISTIC
IS
BEGIN
  IF p_score IS NULL THEN
    RETURN NULL;
  ELSIF p_score < 0 OR p_score > 100 THEN
    RAISE_APPLICATION_ERROR(-20020, 'Score out of range 0-100: ' || p_score);
  END IF;

  RETURN CASE
           WHEN p_score >= 80 THEN 'A'
           WHEN p_score >= 70 THEN 'B'
           WHEN p_score >= 60 THEN 'C'
           WHEN p_score >= 50 THEN 'D'
           ELSE 'F'
         END;
END get_letter_grade;
/
SHOW ERRORS
