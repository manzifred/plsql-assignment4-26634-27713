-- ============================================================
-- 02_insert_sample_data.sql
-- Scores are inserted WITHOUT grade letters on purpose:
-- the bulk_grade_course procedure assigns them later.
-- ============================================================
INSERT INTO students (student_id, full_name, email, status) VALUES (1,  'Aline Uwase',      'aline.uwase@auca.ac.rw',   'ACTIVE');
INSERT INTO students (student_id, full_name, email, status) VALUES (2,  'Jean Bosco Niyonzima','jb.niyonzima@auca.ac.rw','ACTIVE');
INSERT INTO students (student_id, full_name, email, status) VALUES (3,  'Grace Mukamana',   'grace.mukamana@auca.ac.rw','ACTIVE');
INSERT INTO students (student_id, full_name, email, status) VALUES (4,  'Patrick Habimana', 'patrick.h@auca.ac.rw',     'ACTIVE');
INSERT INTO students (student_id, full_name, email, status) VALUES (5,  'Diane Ingabire',   'diane.ingabire@auca.ac.rw','ACTIVE');
INSERT INTO students (student_id, full_name, email, status) VALUES (6,  'Samuel Nshuti',    'samuel.nshuti@auca.ac.rw', 'ACTIVE');
INSERT INTO students (student_id, full_name, email, status) VALUES (7,  'Eric Mugisha',     'eric.mugisha1@auca.ac.rw', 'ACTIVE');
INSERT INTO students (student_id, full_name, email, status) VALUES (8,  'Eric Mugisha',     'eric.mugisha2@auca.ac.rw', 'ACTIVE');  -- same name as 7 (TOO_MANY_ROWS demo)
INSERT INTO students (student_id, full_name, email, status) VALUES (9,  'Claire Uwimana',   'claire.uwimana@auca.ac.rw','SUSPENDED');
INSERT INTO students (student_id, full_name, email, status) VALUES (10, 'David Kamanzi',    'david.kamanzi@auca.ac.rw', 'ACTIVE');

INSERT INTO courses (course_id, title, credits, capacity) VALUES ('INSY8311', 'Database Development with PL/SQL', 3, 3);  -- small capacity: full-course demo
INSERT INTO courses (course_id, title, credits, capacity) VALUES ('INSY8312', 'Web Development',                  3, 40);
INSERT INTO courses (course_id, title, credits, capacity) VALUES ('INSY8313', 'Computer Networks',                4, 40);
INSERT INTO courses (course_id, title, credits, capacity) VALUES ('MATH101',  'Calculus I',                       4, 50);
INSERT INTO courses (course_id, title, credits, capacity) VALUES ('ENGL101',  'Academic English',                 2, 50);

-- INSY8311 is now full (3/3)
INSERT INTO enrollments (student_id, course_id, semester, score) VALUES (1, 'INSY8311', '2026A', 85);
INSERT INTO enrollments (student_id, course_id, semester, score) VALUES (2, 'INSY8311', '2026A', 72);
INSERT INTO enrollments (student_id, course_id, semester, score) VALUES (3, 'INSY8311', '2026A', 55);
INSERT INTO enrollments (student_id, course_id, semester, score) VALUES (1, 'INSY8312', '2026A', 90);
INSERT INTO enrollments (student_id, course_id, semester, score) VALUES (2, 'INSY8312', '2026A', 64);
INSERT INTO enrollments (student_id, course_id, semester, score) VALUES (3, 'INSY8312', '2026A', NULL);
INSERT INTO enrollments (student_id, course_id, semester, score) VALUES (4, 'INSY8313', '2026A', 78);
INSERT INTO enrollments (student_id, course_id, semester, score) VALUES (5, 'INSY8313', '2026A', NULL);
INSERT INTO enrollments (student_id, course_id, semester, score) VALUES (5, 'MATH101',  '2026A', 48);
INSERT INTO enrollments (student_id, course_id, semester, score) VALUES (6, 'MATH101',  '2026A', 66);
INSERT INTO enrollments (student_id, course_id, semester, score) VALUES (6, 'ENGL101',  '2026A', NULL);
INSERT INTO enrollments (student_id, course_id, semester, score) VALUES (7, 'ENGL101',  '2026A', 81);
INSERT INTO enrollments (student_id, course_id, semester, score) VALUES (10,'MATH101',  '2026A', NULL);

COMMIT;
