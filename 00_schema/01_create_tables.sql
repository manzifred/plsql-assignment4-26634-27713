-- ============================================================
-- 01_create_tables.sql
-- Student Registration and Grading System (INSY 8311)
-- Run first. Safe to re-run: drops old objects if they exist.
-- ============================================================
SET SERVEROUTPUT ON

BEGIN
  FOR t IN (SELECT table_name FROM user_tables
            WHERE table_name IN ('GRADE_AUDIT','ENROLLMENTS','COURSES','STUDENTS','PERF_DEMO')) LOOP
    EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS PURGE';
  END LOOP;
  FOR ty IN (SELECT type_name FROM user_types WHERE type_name IN ('T_NUM_LIST','T_SCORE_VARRAY')) LOOP
    EXECUTE IMMEDIATE 'DROP TYPE ' || ty.type_name || ' FORCE';
  END LOOP;
END;
/

-- ---------- Collection types (SQL level, usable as procedure parameters) ----------
CREATE OR REPLACE TYPE t_num_list AS TABLE OF NUMBER;          -- nested table
/
CREATE OR REPLACE TYPE t_score_varray AS VARRAY(100) OF NUMBER(5,2); -- VARRAY
/

-- ---------- Tables ----------
CREATE TABLE students (
  student_id  NUMBER(6)     CONSTRAINT pk_students PRIMARY KEY,
  full_name   VARCHAR2(100) NOT NULL,
  email       VARCHAR2(100) NOT NULL CONSTRAINT uq_students_email UNIQUE,
  status      VARCHAR2(10)  DEFAULT 'ACTIVE' NOT NULL
              CONSTRAINT ck_students_status CHECK (status IN ('ACTIVE','SUSPENDED','GRADUATED'))
);

CREATE TABLE courses (
  course_id   VARCHAR2(10)  CONSTRAINT pk_courses PRIMARY KEY,
  title       VARCHAR2(100) NOT NULL,
  credits     NUMBER(1)     NOT NULL CONSTRAINT ck_courses_credits CHECK (credits BETWEEN 1 AND 6),
  capacity    NUMBER(3)     NOT NULL CONSTRAINT ck_courses_capacity CHECK (capacity > 0)
);

CREATE TABLE enrollments (
  enrollment_id NUMBER GENERATED ALWAYS AS IDENTITY CONSTRAINT pk_enrollments PRIMARY KEY,
  student_id    NUMBER(6)    NOT NULL CONSTRAINT fk_enr_student REFERENCES students(student_id),
  course_id     VARCHAR2(10) NOT NULL CONSTRAINT fk_enr_course  REFERENCES courses(course_id),
  semester      VARCHAR2(10) NOT NULL,
  score         NUMBER(5,2)  CONSTRAINT ck_enr_score CHECK (score BETWEEN 0 AND 100),
  grade_letter  VARCHAR2(1)  CONSTRAINT ck_enr_grade CHECK (grade_letter IN ('A','B','C','D','F')),
  enrolled_on   DATE DEFAULT SYSDATE NOT NULL,
  CONSTRAINT uq_enr_student_course UNIQUE (student_id, course_id, semester)
);

CREATE TABLE grade_audit (
  audit_id      NUMBER GENERATED ALWAYS AS IDENTITY CONSTRAINT pk_grade_audit PRIMARY KEY,
  enrollment_id NUMBER NOT NULL CONSTRAINT fk_audit_enr REFERENCES enrollments(enrollment_id) ON DELETE CASCADE,
  old_score     NUMBER(5,2),
  new_score     NUMBER(5,2) NOT NULL,
  changed_on    DATE DEFAULT SYSDATE NOT NULL,
  changed_by    VARCHAR2(30) DEFAULT USER NOT NULL
);

-- Table used only by the bulk vs row-by-row performance demo
CREATE TABLE perf_demo (
  id  NUMBER,
  val VARCHAR2(50)
);

CREATE INDEX ix_enr_course_sem ON enrollments(course_id, semester);
CREATE INDEX ix_enr_student    ON enrollments(student_id);
