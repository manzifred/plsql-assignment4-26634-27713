# PL/SQL Assignment IV – Student Registration and Grading System

**Course:** Database Development with PL/SQL (INSY 8311)
**Instructor:** Eric Maniraguha  |  **Class group:** D (Friday)

## Group members
| Name | Student ID |
|------|-----------|
| MANZI Fred | 26634 |
| MANZI Michael | 27713 |

## Application description
A university **student registration and grading** system. Students enroll in courses
for a semester, lecturers record scores, letter grades are assigned, and GPAs are
calculated.

**Requirements**
- Only `ACTIVE` students can enroll; a student cannot enroll twice in the same course and semester.
- A course cannot exceed its capacity.
- Scores are 0–100; A ≥ 80, B ≥ 70, C ≥ 60, D ≥ 50, otherwise F.
- Every score change is written to an audit table.
- Only un-graded enrollments can be dropped.
- GPA is credit-weighted (A=4 … F=0); it is `NULL` when a student has no graded courses.

## Database schema
`students` (1) —< `enrollments` >— (1) `courses`; `grade_audit` references `enrollments`.
`perf_demo` is a scratch table for the performance demo. Types `t_num_list` (nested table)
and `t_score_varray` (VARRAY) are created in `00_schema/01_create_tables.sql`.
Constraints: PKs, FKs, UNIQUE (email; student+course+semester), CHECKs (status, credits,
capacity, score range, grade letter), NOT NULL, DEFAULTs.

## Where each requirement is demonstrated
| Requirement | Where |
|---|---|
| User-defined records | `enroll_student`, `print_course_report` |
| `%ROWTYPE` records | `enroll_student`, `record_score` |
| Associative arrays | `bulk_grade_course` |
| Nested table / VARRAY | `t_num_list` in `bulk_enroll_students`, `compare_bulk_vs_row`; `t_score_varray` type |
| Implicit cursors (`SQL%ROWCOUNT/FOUND/NOTFOUND`) | `enroll_student`, `record_score`, `drop_enrollment` |
| Explicit cursors (OPEN/FETCH/CLOSE, FOR loop) | `print_course_report`, `calculate_gpa` |
| BULK COLLECT | `bulk_grade_course` |
| FORALL + SAVE EXCEPTIONS | `bulk_grade_course`, `bulk_enroll_students`, `compare_bulk_vs_row` |
| Predefined exceptions | `NO_DATA_FOUND`, `TOO_MANY_ROWS` (`get_student_id_by_name`), `DUP_VAL_ON_INDEX` |
| User-defined exceptions + `RAISE_APPLICATION_ERROR` | all procedures/functions (codes -20001 … -20099) |

## How to run
Run these in SQL*Plus, SQL Developer (as a script, F5) or SQLcl, in a schema with
`CREATE TABLE`, `CREATE TYPE`, `CREATE PROCEDURE` privileges.
1. `00_schema/01_create_tables.sql`
2. `00_schema/02_insert_sample_data.sql`
3. Every file in `01_procedures/`
4. Every file in `02_functions/`
5. `03_tests/test_success_cases.sql`, then `03_tests/test_error_cases.sql`
6. Save screenshots of each test's output into `screenshots/`

(Procedures do not call the functions, so the compile order above has no dependency problems.)

## Error code reference
-20001 not found · -20002 inactive student · -20003 course full · -20004 duplicate enrollment ·
-20010 invalid score · -20011 enrollment not found · -20020–20024 function errors ·
-20030/-20031 drop errors · -20040 course not found · -20050/-20051 bulk grading ·
-20060/-20061 bulk enroll · -20070 bad row count · -20099 unexpected error (message includes `SQLERRM`).

## Use of AI
An AI assistant (Kiro, powered by Claude by Anthropic) was used to help generate and review the schema,
PL/SQL code, tests and documentation. MANZI Fred and MANZI Michael reviewed, ran and tested everything,
and both members can explain all of the code.

See `docs/IMPLEMENTATION_NOTES.md` for implementation and performance notes.
