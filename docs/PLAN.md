# OrbitriX: Project Plan (for Copilot and teammates)

OrbitriX is a Student Lifecycle Platform for Maatram (problem MH26-05). One person record follows a person from application to student to alumnus. Use fake data only. A visual version of this plan is in `OrbitriX_Solution_Flowchart.pdf` (same folder).

## Working rules for Copilot (read first)

- I am a beginner on Windows. Use `npm.cmd` and `npx.cmd` in PowerShell.
- Work on ONE phase at a time, the one I name. Do not start later phases.
- Before each command, say in one simple sentence what it does, then wait for my approval.
- Never delete files or run reset commands without asking first. `npx.cmd supabase db reset` is allowed only on the local database, after asking.
- Never print, save or commit keys, passwords or `.env` files. Only `.env.example` (names, no values) is committed.
- Use only fake data. No real student details, ever.
- Change the database only with new migration files (`npx.cmd supabase migration new <name>`). Never edit a migration that has already been applied.
- Every change to important data must save its event row and audit row in the same transaction.
- After each phase: run the "Done when" checks, show me the results, update the Status section below, and commit.
- If a command fails, stop, show the error and explain it simply.

## Fixed facts

- Stack: React + Tailwind (frontend), Supabase run locally with the Supabase CLI (Postgres, Auth, Storage), a Node.js worker for replay, Docker Desktop.
- Tests: pgTAP for database logic, Vitest for worker and frontend logic.
- One `people` record per person. Admission, student and alumnus are stages of the same record. One Maatram ID.
- Roles: applicant, volunteer, panel, staff, zone coordinator, student, alumnus.
- 4 zones (Zone A to D), each with fake colleges, each with fake departments.
- 4 admission levels: 1 physical verification (volunteer home visit), 2 online meeting (rules and regulations), 3 online one-to-one panel interview, 4 panel interview at the Chennai head office.
- Application statuses: draft, submitted, in_process, shortlisted, selected, rejected.
- Selected or rejected needs a reason. Selected also needs zone, college and department.
- Each year is a separate cycle. Submissions are blocked outside the cycle dates.
- Volunteering is counted as number of completed activities, not hours. The count is calculated from rows, never stored as a separate number.
- Salary (CTC) is optional, entered as a range, and visible to staff only.

## Status (update after each phase)

- Phase 0: done
- Phase 1: done
- Phase 2: done
- Phase 3: in progress
- Phases 4 to 11: planned

## Phases (build in this order)

| Phase | Build | Done when | Total |
|---|---|---|---|
| 0 Setup tools | VS Code, Node.js, Git, Docker Desktop | Versions print in the terminal. Docker Desktop is running. | 5% |
| 1 Local base | Supabase CLI, local start, `people` table, 5 fake rows | Studio opens at 127.0.0.1:54323. Table Editor shows 5 rows. | 10% |
| 2 Team repo | Private GitHub repo, README, `.env.example` | Repo visible on GitHub. No keys committed. A teammate can clone it. | 15% |
| 3 Admission database | zones, colleges, departments, cycles, applications, application_levels, application_status_history, triggers, rules, RLS switched on | Submit after close fails. Reject without reason fails. Status change adds a history row. Deleting history fails. | 25% |
| 4 Login, roles, RLS | Sign-in, roles, access policies per role | Applicant sees only own application. Volunteer sees only assigned visits. Coordinator sees own zone. Staff see all. | 35% |
| 5 Admission screens | Apply form with drafts, applicant tracker, staff review, bulk select or reject with reasons, student created on selection | Apply, shortlist, select works end to end. Student with Maatram ID appears. Cycle filter and year-over-year comparison work. | 50% |
| 6 Smart uploads | Signed link function, bucket limits, check after upload, storage settings in `.env` | Valid file uploads. Oversized and wrong-type files are rejected. Changing `.env` points to other storage. | 60% |
| 7 Event log and replay | events and outbox tables, triggers, replay worker with 3 modes and a bookmark | Replay gives no duplicate emails. Out-of-order commit is still processed. Restart resumes from the bookmark. | 75% |
| 8 Alumni career tracker | career rows with source, company rules and alias list, profile built by replay, search by company | Who-works-at-a-company returns the right people across spellings. Profile matches the latest job. | 85% |
| 9 Student and alumni views | Dashboard, Connect me as Alumni, zone event list, volunteering count | Student sees zone and college. Button changes stage and saves an event. Count equals completed activities. | 92% |
| 10 Data, tests, one command | Seed script, tests, README, start command | Fresh clone runs with one command. All tests pass. No secrets in code. | 97% |
| 11 Demo and submit | Short demo video, final read-through | All 6 demo scenarios shown. README is clear. Submitted. | 100% |

## Planned tables (names can change)

people, zones, colleges, departments, cycles, applications, application_levels, application_status_history, events, outbox, bookmarks, career_history, company_aliases, files, volunteer_activities, event_list (zone events).

## Rules to implement exactly

### Event log and replay
- `events` is append-only: no update, no delete.
- The change, its event row and its audit row are saved in one transaction.
- Replay modes: from the start, from a given time, from the worker's saved bookmark.
- The worker reads only events from fully finished transactions, so a late commit is never skipped.
- Emails go through an `outbox` table with a unique key (event, person, email type). A second send with the same key is skipped.
- A repeated event with the same key is stored once.
- If the worker or database stops, the worker resumes from its bookmark. An event that cannot be processed is marked failed with an error note, and the rest continue.

### Company name rules (run in this order)
1. Make lowercase.
2. Trim spaces and remove punctuation.
3. Drop endings such as ltd, limited, pvt, inc, llc.
4. Look up the alias list for names that need a human decision.
5. The same input always gives the same result.

### Career profile (suggested rule, to be confirmed by the team)
- Each job is a row: company, role, domain, start date, end date, source (self-reported, referral, placement).
- The current profile is built by replaying these rows. Latest start date wins. If tied, placement beats referral beats self-reported.

### Smart uploads
- The browser asks the server for an upload link and declares file type and size.
- The server rejects wrong types and oversized files before issuing a short-lived signed link.
- The browser uploads directly to S3-compatible storage (MinIO or Supabase Storage).
- The server checks the stored file's real type and size afterwards. If the check fails, the file is removed and the upload is rejected.
- Switching storage provider changes only `.env` values (endpoint, bucket, access key, secret key).

## Scope

- Must: the 4 required parts (event log with replay, alumni career tracker, admission end to end, smart uploads), zones, 4 levels, roles, simple student dashboard, Connect me as Alumni.
- Should: zone event list, volunteering count, resume upload.
- Later: QR attendance, CGPA tracking, interview counts, mentoring, CTC analytics, notice board.

## Demo script (6 scenarios)

1. Replay from the start, from a time, and from the bookmark. No duplicate email is sent.
2. Commit two events in reverse order. The worker still processes both.
3. Ask who works at a company. Different spellings return the same people, each with its source.
4. Apply with a draft, submit, move through levels, bulk select with a reason. A student with a Maatram ID appears.
5. Switch between 2025 and 2026. Show the year-over-year comparison and the audit trail.
6. Upload a valid file, then an oversized file. The oversized file is rejected with a clear message.
