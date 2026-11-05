# Implementation and Performance Notes

## Design overview
Business rules live in stored procedures and functions, not in the client. Procedures
change data (`enroll_student`, `record_score`, `drop_enrollment`, `bulk_grade_course`,
`bulk_enroll_students`), report (`print_course_report`) or benchmark
(`compare_bulk_vs_row`). Functions compute values and can be used in SQL
(`get_letter_grade`, `calculate_gpa`, `get_seats_left`, `get_student_id_by_name`).
Procedures and functions never `COMMIT`; the caller controls the transaction.

## Records
- **`%ROWTYPE`** (`students%ROWTYPE`, `enrollments%ROWTYPE`) holds a whole row fetched by `SELECT *`, so the code stays correct if columns are added.
- **User-defined records** (`r_course_check`, `r_line`) group only the fields needed, e.g. the result of a join/sub-query.

## Collections
- **Associative arrays** (`INDEX BY PLS_INTEGER`) in `bulk_grade_course` hold ids, scores and computed letters in parallel.
- **Nested table** `t_num_list` is a SQL-level type, so a list of student ids can be passed as a parameter to `bulk_enroll_students`.
- **VARRAY** `t_score_varray` is defined for fixed-size score lists (max 100). It is demonstrated in `03_tests/test_success_cases.sql` (TEST 9): a VARRAY of 10 scores is populated, iterated, and each score is passed to `get_letter_grade`; the average score, `.LIMIT`, and `.COUNT` are printed.

## Cursors
- **Implicit:** `SQL%ROWCOUNT`, `SQL%FOUND`, `SQL%NOTFOUND` are read right after the DML. `SQL%ROWCOUNT` is copied into a variable immediately because the next SQL statement overwrites it. In `drop_enrollment`, `SQL%NOTFOUND` triggers a second query to give the *real* reason (missing vs already graded).
- **Explicit:** `print_course_report` uses a parameterised cursor with `OPEN/FETCH/CLOSE`, `%NOTFOUND`, `%ROWCOUNT`, `%ISOPEN` (closed in the handler to avoid cursor leaks). Cursor FOR loops are used for the grade distribution and in `calculate_gpa`.

## Exception handling approach
- Predefined: `NO_DATA_FOUND`, `TOO_MANY_ROWS`, `DUP_VAL_ON_INDEX`.
- User-defined: `e_student_inactive`, `e_course_full`, `e_invalid_score`, `e_already_graded`, `e_nothing_to_grade`, …
- Each is translated into `RAISE_APPLICATION_ERROR` with a code in -20001…-20099 and a message naming the offending value.
- `WHEN OTHERS` always **re-raises** as -20099 with `SQLERRM`; nothing is swallowed. Functions raise errors instead of returning fake values (e.g. `calculate_gpa` returns `NULL`, not `0`, if there are no graded courses).

## Bulk processing and performance
Row-by-row processing (`FOR … LOOP … INSERT/UPDATE`) makes one **context switch** between
the PL/SQL engine and the SQL engine per row. With N rows that is N switches, each with
parse/dispatch overhead.

`BULK COLLECT` fetches all rows into a collection in **one** switch, and `FORALL` sends the
whole collection to the SQL engine in **one** switch, which runs the DML for every element.
Typically this is several times faster for thousands of rows (`compare_bulk_vs_row` measures it
with `DBMS_UTILITY.GET_TIME`). Example run with 50 000 rows on our machine:
- Row-by-row : ~509 centiseconds
- FORALL     : ~10 centiseconds  (~50.9× faster)

Practical considerations:
- Collections live in PGA memory. For very large tables use `BULK COLLECT … LIMIT n` in a loop (e.g. 1000) instead of loading everything.
- `FORALL` handles only a single DML statement, with the index used directly in the statement.
- **`SAVE EXCEPTIONS`** lets the rest of the batch continue when some rows fail. Failures are raised afterwards as ORA-24381; `SQL%BULK_EXCEPTIONS(j).ERROR_INDEX` / `ERROR_CODE` identify the failing element and error. `bulk_enroll_students` reports failed rows (duplicates → ORA-00001, unknown student → ORA-02291) and keeps the valid ones; `bulk_grade_course` reports and raises -20051 so the failure isn't hidden.
- `compare_bulk_vs_row` runs as an `AUTONOMOUS_TRANSACTION` and rolls back, so benchmarking never affects real data or the caller's transaction.
- Indexes `ix_enr_course_sem` and `ix_enr_student` support the main query patterns.
