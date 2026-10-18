# DevTeam Task Manager — Full Test Plan

**Purpose:** Verify the existing DevTeam Task Manager against the recruitment assignment before adding features or starting the next sprint.

**Known environment:** Windows 11, .NET SDK 10 installed, SQL Server with Windows authentication, VS Code, API currently shown at `http://localhost:5074`.

**Important:** This is a test plan, not proof that the tests have passed. Record actual results as PASS, FAIL, BLOCKED, or NOT TESTED. Do not run destructive tests against valuable data. Use a development/test database.

---

## 1. Test execution rules

1. Inspect the current Git status and preserve any existing user changes.
2. Confirm the API base URL and database name before testing.
3. Back up the development database before tests that create, update, close, or delete records.
4. Use unique test names such as `QA-2026-10-13-Task-A`.
5. Do not paste passwords, tokens, or full connection strings into test reports.
6. A visible UI control is not a passing test. Verify the API response and persisted database state where possible.
7. Do not run the sprint-closure test on a sprint containing important real data.
8. Capture failed request URL, HTTP status, response body (with secrets removed), and reproduction steps.

## 2. Test result log

For every test below, record:

| Field | Value |
|---|---|
| Test ID | e.g. ENV-01 |
| Result | PASS / FAIL / BLOCKED / NOT TESTED |
| Actual result | What happened |
| Evidence | Screenshot, response, or log |
| Defect / notes | Error details or follow-up |

---

## 3. Environment and project checks

### ENV-01 — .NET SDK
Run:
```powershell
dotnet --list-sdks
dotnet --info
```
**Expected:** A .NET 10 SDK is listed and the command completes without an SDK-resolution error.

### ENV-02 — Project target framework
Inspect the actual project file:
```powershell
Get-Content ".\DevTeamTaskManager.Api\DevTeamTaskManager.Api.csproj"
```
**Expected:** `TargetFramework` and package versions are known. Do not assume the project targets `net10.0` just because the SDK is installed.

### ENV-03 — Git working tree
Run:
```powershell
git status --short --branch
```
**Expected:** Existing changes are identified and preserved. Do not discard or reset changes as part of testing.

### ENV-04 — Restore
From the solution directory:
```powershell
dotnet restore
```
**Expected:** Restore succeeds, or any package/network error is recorded.

### ENV-05 — Build
From the solution directory:
```powershell
dotnet build --no-restore
```
**Expected:** Build succeeds with no errors. Record warnings separately; investigate warnings that affect runtime behavior.

### ENV-06 — API process
Start the existing application using its normal launch method. Confirm the configured URL in the terminal output or launch settings.
**Expected:** Application starts without an unhandled exception and responds at the configured local URL.

### ENV-07 — OpenAPI / Swagger
Open the existing Swagger URL if enabled, or inspect the OpenAPI document at:
`http://localhost:5074/swagger/v1/swagger.json`
**Expected:** The document loads and lists the routes actually exposed by the API. If Swagger is disabled or uses another URL, record the real configuration instead of changing it just for this test.

### ENV-08 — SQL Server service and connectivity
Check likely SQL Server services:
```powershell
Get-Service |
  Where-Object { $_.Name -like "MSSQL*" -or $_.Name -like "SQLBrowser" } |
  Format-Table Name, Status, DisplayName -AutoSize
```
If `sqlcmd` is installed, substitute the real server/instance:
```powershell
sqlcmd -S "YOUR_SERVER_INSTANCE" -E -Q "SELECT @@SERVERNAME AS ServerName, DB_NAME() AS CurrentDatabase;"
```
**Expected:** The intended instance is reachable with Windows authentication. Do not guess the instance name or change service settings without evidence.

### ENV-09 — Database schema / migrations
Inspect migration files and the app's database configuration locally. Do not share secrets.
**Expected:** The configured database is the intended development database, required tables exist, and migrations are consistent with the current model. Do not apply migrations until the target database is confirmed and backed up if needed.

---

## 4. Task management (CRUD)

Run these tests in the UI and verify the corresponding API request/response. Use only the actual DTO schema shown by Swagger or the source code.

### TASK-01 — Read/list tasks
**Steps:** Open the task dashboard and call the task-list GET endpoint.
**Expected:** A successful response; the UI displays the returned tasks without a JavaScript error.

### TASK-02 — Create valid task
**Data:** Use a unique client/project, description, assigned developer, positive estimate, future due date, valid priority and valid status.
**Expected:** Creation succeeds; the returned task has an identifier; it appears in the list after refresh and remains after API restart.

### TASK-03 — Required-field validation
Try creating a task with each required field omitted or blank, one field at a time.
**Expected:** A clear validation response (typically HTTP 400) and no invalid record persisted. Confirm the actual contract rather than assuming the status code.

### TASK-04 — Invalid estimate
Try zero, negative, malformed, and excessively large estimates where the API accepts the corresponding input type.
**Expected:** Invalid values are rejected or handled according to a documented business rule; no server error or corrupt value.

### TASK-05 — Invalid enum values
Submit unsupported priority and status values using the real DTO format.
**Expected:** Invalid values are rejected; the API does not silently store an unintended value.

### TASK-06 — Update task
Change description, client, assignment, priority and status using the supported update mechanism.
**Expected:** Changes are returned by the API and persist after refresh/restart.

### TASK-07 — Missing task ID
Request or update a nonexistent task ID.
**Expected:** A controlled not-found response; no unhandled exception.

### TASK-08 — Delete task (only if supported)
Use a disposable test task and the actual delete endpoint, if one exists.
**Expected:** Deletion follows the API contract and the task no longer appears. Do not infer that DELETE is required if the assignment only requires create/view/edit.

---

## 5. Listing, filters and inline editing

### LIST-01 — Client filter
Filter by a client that has matching tasks.
**Expected:** Only matching tasks remain. Test a client with no matches.

### LIST-02 — Developer filter
Filter by assigned developer.
**Expected:** Only tasks assigned to the selected developer remain; unassigned-task behavior is consistent.

### LIST-03 — Status filter
Test each supported status: To do, In progress, Completed (use the application's exact enum labels).
**Expected:** Only tasks with the selected status appear.

### LIST-04 — Priority filter
Test each supported priority: Low, Medium, High, Critical (use the application's exact enum labels).
**Expected:** Only matching tasks appear.

### LIST-05 — Combined filters
Apply client + developer + status + priority together.
**Expected:** Filters combine correctly rather than one filter overriding the others.

### LIST-06 — Inline estimate update
Change a task estimate from the listing/card without opening the full edit form.
**Expected:** An asynchronous API request is sent; success is reflected in the UI and persisted. On API failure, the user receives feedback and the UI does not falsely show a saved value.

### LIST-07 — Inline due-date update
Change the due date inline if the UI supports it.
**Expected:** Date is sent in the API's required format, persisted, and displayed consistently. If the feature is absent, record it as a gap.

### LIST-08 — Empty and boundary results
Test no matching tasks, long descriptions, special characters, and dates at the boundary of allowed values.
**Expected:** No layout break, unhandled exception, or misleading result.

---

## 6. Sprint planning and capacity

### SPRINT-01 — List sprints
**Expected:** The API and UI list existing sprints consistently.

### SPRINT-02 — Create valid sprint
Create a disposable sprint with a unique name, start date and end date.
**Expected:** Sprint is created and persists after refresh.

### SPRINT-03 — Invalid sprint dates
Try end date earlier than start date and any missing required dates.
**Expected:** Invalid sprint is rejected with a clear message; no invalid sprint is persisted.

### SPRINT-04 — Assign tasks to sprint
Associate a few disposable tasks with a sprint using the actual supported endpoint/UI.
**Expected:** The sprint's task list contains the assigned tasks; other sprints are unaffected.

### SPRINT-05 — Capacity calculation
Compare displayed totals with task estimates and actual time entries for the selected sprint.
**Expected:** Totals match the included tasks and time entries. Document whether the developer percentage means share of sprint estimate or utilization against available capacity.

### SPRINT-06 — Zero-estimate / empty sprint
Test an empty sprint and, if allowed, a sprint with zero total estimated hours.
**Expected:** No divide-by-zero, NaN, Infinity, or misleading percentage.

### SPRINT-07 — Sprint isolation
Select two different sprints.
**Expected:** Task cards, counts and report totals change to match the selected sprint.

### SPRINT-08 — Close sprint
Use a disposable sprint only.
**Expected:** Closure follows the business rule; repeated closure is handled safely; tasks and reports remain consistent. Confirm whether closed sprints should block edits or only mark the sprint closed.

---

## 7. Kanban workflow

### KANBAN-01 — Columns
**Expected:** Tasks are grouped under the correct status columns.

### KANBAN-02 — Change status
Move a disposable task from To do → In progress → Completed using the UI's supported action or drag-and-drop.
**Expected:** Status updates immediately or after a clear success response, and persists after refresh.

### KANBAN-03 — Failed status update
Temporarily test against an invalid ID or an unavailable API in a safe local test setup.
**Expected:** The UI reports failure and restores/reconciles the task's actual server status.

### KANBAN-04 — Sprint-specific board
**Expected:** Only tasks belonging to the selected sprint appear if the assignment requires a board for a particular sprint.

### KANBAN-05 — Concurrent changes
Change the same task in two browser tabs.
**Expected:** The final displayed status reconciles with the server; no silent false success.

---

## 8. Time entry and reporting

### TIME-01 — Record valid time
Record a positive duration against a valid task using the actual time-entry DTO.
**Expected:** Entry is created and linked to the correct task/developer.

### TIME-02 — Invalid duration
Try zero, negative, malformed or otherwise invalid durations according to the accepted unit.
**Expected:** Invalid durations are rejected or handled by a documented rule.

### TIME-03 — Missing task
Attempt a time entry for a nonexistent task.
**Expected:** Controlled validation/not-found response; no orphan record.

### TIME-04 — Task report
Compare the initial estimate against the sum of all time entries for that task.
**Expected:** Actual time equals the sum of valid entries, with the unit displayed consistently.

### TIME-05 — Sprint report
Compare report totals against the tasks assigned to that sprint.
**Expected:** No double counting; tasks from other sprints are excluded according to the documented rule.

### TIME-06 — Overrun logic
Test a task where actual time is below, equal to, and above its estimate.
**Expected:** The report correctly distinguishes under-estimate, on-estimate and over-estimate cases.

### TIME-07 — No time entries
Open a task or sprint with no time entries.
**Expected:** Report shows zero actual time without crashing or displaying invalid numeric values.

---

## 9. API quality and error handling

### API-01 — HTTP methods and routes
Compare Swagger/OpenAPI with the assignment and UI requests.
**Expected:** Each required operation uses the intended route and HTTP method.

### API-02 — HTTP status codes
Verify success, validation, not-found and server-error cases.
**Expected:** Responses are consistent and do not return HTTP 200 for failed operations.

### API-03 — JSON contract
Inspect responses for stable field names, correct date formats, numeric units and null handling.
**Expected:** Frontend and backend agree on the contract.

### API-04 — Async frontend calls
Use browser DevTools → Network while filtering and editing.
**Expected:** Calls are asynchronous; the page does not require a full reload for inline edits.

### API-05 — Server errors
Review the API terminal output when a request fails.
**Expected:** No sensitive connection strings or secrets are exposed to the client.

### API-06 — Input safety
Test text containing apostrophes, accents and ordinary punctuation.
**Expected:** Data is handled safely; database operations use parameterized queries/EF Core rather than unsafe string concatenation.

### API-07 — Duplicate requests
Submit a create request twice only in a test environment.
**Expected:** The system behaves according to its documented duplicate-handling rules and does not create accidental duplicates from a single UI action.

---

## 10. UI regression checks

- [ ] Dashboard loads without a blank screen.
- [ ] No uncaught JavaScript errors in browser DevTools Console.
- [ ] All visible buttons have a working action.
- [ ] Loading and failure feedback are understandable.
- [ ] Task cards show the correct client, description, assignee, priority and estimate.
- [ ] Filters work individually and in combination.
- [ ] Inline edits do not accidentally trigger other card actions.
- [ ] Sprint selection updates the report and board.
- [ ] Layout remains usable at typical desktop resolution.
- [ ] Refreshing the page does not lose successfully saved data.

---

## 11. Final acceptance checklist

Mark an item PASS only after executing it and collecting evidence.

- [ ] Build succeeds.
- [ ] API starts reliably.
- [ ] SQL Server Windows-authenticated connection succeeds.
- [ ] Task create, read and update work.
- [ ] Client, developer, status and priority filters work.
- [ ] Estimate inline editing persists through the API.
- [ ] Due-date inline editing works, or the gap is documented.
- [ ] Sprint creation validates dates.
- [ ] Tasks can be assigned to and viewed within a sprint.
- [ ] Sprint capacity report totals are correct.
- [ ] Kanban status changes persist.
- [ ] Sprint closure follows the intended rules.
- [ ] Time entries are validated and saved.
- [ ] Task/sprint reports compare estimate with actual time correctly.
- [ ] No critical UI console errors or unhandled API exceptions.
- [ ] Known gaps are documented for the recruitment demonstration.

## 12. Suggested test order for a short deadline

1. ENV-01 through ENV-07: establish a reproducible build and running API.
2. Confirm database instance and schema before making any database changes.
3. TASK-01, TASK-02, TASK-06: verify core task persistence.
4. LIST-01 through LIST-07: verify filters and inline edits.
5. SPRINT-01 through SPRINT-07 and KANBAN-01 through KANBAN-04.
6. TIME-01 through TIME-07.
7. Run the final acceptance checklist and record remaining gaps.

**Completion rule:** The test plan is complete only when every required test has a recorded result. “Visible in the UI” is not equivalent to “verified end-to-end.”
