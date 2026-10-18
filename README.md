# DevTeam Task Manager

[Version française](README.md)

Internal task management tool for development teams: centralise client requests, organise sprints with a Kanban board, and track the time developers spend.

Built as a technical test (working prototype).

## Table of contents

- [Features](#features)
- [Tech stack](#tech-stack)
- [Project structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Setup and run](#setup-and-run)
- [Running with Docker](#running-with-docker)
- [Demo data](#demo-data)
- [Tests](#tests)
- [REST API](#rest-api)
- [Business rules](#business-rules)
- [Data integrity and security](#data-integrity-and-security)
- [Known limitations](#known-limitations)
- [Roadmap](#roadmap)

## Features

**Task management**
- Create, view and edit a task: client, description, assigned developer, estimate (in hours), due date, priority (Low, Medium, High, Critical) and status (To do, In progress, Done).
- Paged list with filters by client, developer, status, priority and sprint.
- Inline editing of the estimate and the due date straight from the list, with no form (transparent API call).

**Sprints and Kanban**
- Create a sprint (name, dates) and attach backlog tasks to it.
- Allocation rate per developer shown as soon as the sprint is created.
- Three-column Kanban board with drag and drop: the status change is saved to the database immediately.
- Sprint closing.

**Time tracking and reports**
- Log time spent on a task, with a date and a note.
- Task report: estimate, total time spent, history of entries, overrun flag.
- Sprint report: total estimated, total spent, workload per developer and an overload alert.

## Tech stack

| Layer | Technologies |
|---|---|
| Backend | .NET 10, ASP.NET Core Web API (controllers), C# |
| Data access | Entity Framework Core 10, migrations |
| Database | SQL Server |
| Frontend | HTML, CSS, JavaScript, jQuery 3.7, jQuery UI 1.13 (drag and drop), Bootstrap 5.3 |
| API documentation | Swagger (Swashbuckle), available in development |
| Tests | xUnit |
| Containers | Docker and Docker Compose (API and SQL Server 2022) |

All calls from the UI to the API are asynchronous (AJAX).

## Project structure

```
DevTeamTaskManager/
├── DevTeamTaskManager.Api/
│   ├── Controllers/      Tasks, Sprints, TimeEntries, Developers
│   ├── Entities/         TaskItem, Sprint, Developer, TimeEntry
│   ├── Enums/            Priority, Status, SprintStatus
│   ├── DTOs/             Request/response objects and PagedResult<T>
│   ├── Data/             AppDbContext and SQL scripts
│   ├── Migrations/       EF Core migrations
│   ├── wwwroot/          User interface (index.html)
│   └── Program.cs
├── DevTeamTaskManager.Tests/   xUnit unit tests
├── docker-compose.yml
└── DevTeamTaskManager.slnx
```

## Prerequisites

- [.NET 10 SDK](https://dotnet.microsoft.com/download)
- SQL Server (Express, LocalDB or a full instance)
- EF Core command-line tool: `dotnet tool install --global dotnet-ef`
- Optional: Docker Desktop

## Setup and run

1. Clone the repository:

   ```bash
   git clone https://github.com/wassimyaich/devteam-task-manager-SQL.git
   cd devteam-task-manager-SQL
   ```

2. Check the connection string in `DevTeamTaskManager.Api/appsettings.json` (key `ConnectionStrings:DefaultConnection`). Default:

   ```
   Server=localhost;Database=DevTeamDb;Trusted_Connection=True;TrustServerCertificate=True;
   ```

3. Create the database and apply the migrations:

   ```bash
   cd DevTeamTaskManager.Api
   dotnet ef database update
   ```

   Migrations are also applied automatically when the application starts.

4. Start the application:

   ```bash
   dotnet run
   ```

   - UI: `http://localhost:5074` (see `Properties/launchSettings.json` for the exact port)
   - Swagger: `/swagger` (Development environment)

## Running with Docker

```bash
docker compose up --build
```

- The UI is available at `http://localhost:5074`.
- The `DevTeamTaskDb` database is created on first start by the migrations. If the API starts before SQL Server is ready, it restarts automatically until the database is available.
- The credentials in `docker-compose.yml` are for local development only. For anything else, use an untracked `.env` file.

## Demo data

A realistic data set is provided: 6 developers, 4 sprints (2 closed, 1 active, 1 planned), 32 tasks and 58 time entries. It covers every business case: tasks over budget, an overloaded developer, backlog tasks, and an unfinished task inside a closed sprint.

**Warning: the script first empties the Developers, Sprints, Tasks and TimeEntries tables.**

```bash
sqlcmd -S localhost -d DevTeamDb -E -C -i DevTeamTaskManager.Api/Data/seed_real_data.sql
```

For Docker, change the `USE DevTeamDb;` line of the script to `USE DevTeamTaskDb;`.

## Tests

From the solution root:

```bash
dotnet test
```

The tests call the real working-days calculation: weekend only, a single day, a week containing a public holiday, a sprint spanning two years, reversed dates.

## REST API

| Method | Route | Description |
|---|---|---|
| GET | `/api/tasks` | Paged list, filters `client`, `assigneeId`, `status`, `priority`, `sprintId`, `unassigned`, `pageNumber`, `pageSize` |
| GET | `/api/tasks/{id}` | Task details with time spent |
| GET | `/api/tasks/{id}/report` | Estimate vs time spent report |
| POST | `/api/tasks` | Create a task |
| PUT | `/api/tasks/{id}` | Full update |
| PATCH | `/api/tasks/{id}/inline` | Update the estimate and/or the due date |
| PATCH | `/api/tasks/{id}/status` | Change the status (Kanban) |
| DELETE | `/api/tasks/{id}` | Delete (409 if time has been logged) |
| GET | `/api/sprints` | List sprints with task count |
| GET | `/api/sprints/active` | Sprints that are not closed |
| POST | `/api/sprints` | Create a sprint, returns the capacity report |
| GET | `/api/sprints/{id}/capacity` | Capacity report and allocation rates |
| PATCH | `/api/sprints/{id}/close` | Close a sprint |
| GET, POST, DELETE | `/api/timeentries` | Time entries |
| GET | `/api/developers` | List developers |
| GET | `/api/developers/search?term=` | Search (autocomplete) |

Enumerations are exchanged as integers:

| Enumeration | Values |
|---|---|
| Priority | 1 Low, 2 Medium, 3 High, 4 Critical |
| Status | 1 To do, 2 In progress, 3 Done |
| SprintStatus | 1 Planned, 2 Active, 3 Closed |

## Business rules

**Working days.** Saturdays and Sundays (`DayOfWeek`), Tunisian public holidays and religious holidays (Hijri calendar) are excluded. Holidays are computed for every year the sprint covers. A sprint must contain at least one working day.

**Capacity and allocation.**

```
developer capacity = sprint working days x 7 h
allocation rate    = estimated hours of their tasks in the sprint / capacity x 100
overloaded         = estimated hours > capacity
```

Every developer appears in the report, including those with no task (0 %).

**Overrun.** A task or a sprint is over budget when the time spent is strictly greater than the initial estimate.

**Time entries.** Duration between 0.1 and 24 h, date not in the future, and at most 24 h per developer per day.

**Closing a sprint.** Tasks stay attached to the closed sprint, which keeps its report accurate. Unfinished tasks are carried over by assigning them to a new sprint. A task cannot be assigned to a closed sprint.

## Data integrity and security

- Parameterised queries through Entity Framework Core (no concatenated SQL).
- Layered validation: data annotations on DTOs, automatic `[ApiController]` validation, explicit checks in controllers (developer and sprint exist, sprint not closed, valid date).
- Cascade delete disabled (`DeleteBehavior.Restrict`) between tasks, developers and time entries. A task with logged time cannot be deleted.
- Indexes on filtered columns (status, priority, client) and a unique developer email.
- Every displayed value is escaped in the UI to limit XSS risk.
- Read queries use `AsNoTracking` and can be cancelled through a `CancellationToken`.

## Known limitations

- No authentication or role management.
- No concurrency control: with simultaneous edits, the last write wins.
- Religious holidays come from the Hijri calendar and can differ by one to two days from the official announcement. Civil public holidays are hard-coded.
- Estimates are entered in hours only.
- Automated tests cover the working-days calculation; there are no integration tests yet.

## Roadmap

1. Extract the capacity and working-days logic into a dedicated service (`ISprintService`).
2. Detailed sprint report, task by task.
3. Optimistic concurrency control (`RowVersion`).
4. Editing of time entries.
5. Use `DateOnly` for dates without a time.
6. Integration tests (`WebApplicationFactory`, SQLite or Testcontainers).
7. JWT authentication and roles.
8. Database `CHECK` constraints on status and priority.

## Author

[@wassimyaich](https://github.com/wassimyaich)
