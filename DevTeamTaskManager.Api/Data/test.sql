-- USE DevTeamDb;
-- GO
-- SET NOCOUNT ON;
-- SET XACT_ABORT ON;
-- BEGIN TRY
--     BEGIN TRANSACTION;
--     -- Tables temporaires pour stocker les ID insérés
--     DECLARE @D TABLE (
--         Id INT PRIMARY KEY);
--     DECLARE @S TABLE (
--         Id INT PRIMARY KEY);
--     DECLARE @T TABLE (
--         Id INT PRIMARY KEY);
--     DECLARE @E TABLE (
--         Id INT PRIMARY KEY);
--     -- Récupération des max ID actuels pour éviter les conflits
--     DECLARE @D0 AS INT = ISNULL((SELECT MAX(Id)
--                                  FROM   dbo.Developers), 0);
--     DECLARE @S0 AS INT = ISNULL((SELECT MAX(Id)
--                                  FROM   dbo.Sprints), 0);
--     DECLARE @T0 AS INT = ISNULL((SELECT MAX(Id)
--                                  FROM   dbo.Tasks), 0);
--     DECLARE @E0 AS INT = ISNULL((SELECT MAX(Id)
--                                  FROM   dbo.TimeEntries), 0);
--     -- 1. Insert 10 developers
--     SET IDENTITY_INSERT dbo.Developers ON;
--     INSERT INTO dbo.Developers (
--         Id,
--         Name,
--         Email
--     )
--     OUTPUT inserted.Id INTO @D (Id)
--     SELECT @D0 + n,
--            CONCAT('Test Developer ', n),
--            CONCAT('test', @D0 + n, '@devteam.local')
--     FROM   (VALUES (1), (2), (3), (4), (5), (6), (7), (8), (9), (10)) AS v(n);
--     SET IDENTITY_INSERT dbo.Developers OFF;
--     -- 2. Insert 5 sprints (Statut : 1 = Planned, 2 = Active, 3 = Closed)
--     SET IDENTITY_INSERT dbo.Sprints ON;
--     INSERT INTO dbo.Sprints (
--         Id,
--         Name,
--         StartDate,
--         EndDate,
--         Status
--     )
--     OUTPUT inserted.Id INTO @S (Id)
--     SELECT @S0 + n,
--            CONCAT('Test Sprint ', n),
--            DATEADD(DAY, (n - 1) * 14, CAST ('2026-10-01' AS DATETIME)),
--            DATEADD(DAY, (n - 1) * 14 + 13, CAST ('2026-10-01' AS DATETIME)),
--            CASE WHEN n = 1 THEN 3 ELSE 2 END -- Le sprint 1 est fermé (3), les autres sont actifs (2)
--     FROM   (VALUES (1), (2), (3), (4), (5)) AS v(n);
--     SET IDENTITY_INSERT dbo.Sprints OFF;
--     -- 3. Insert 35 tasks
--     SET IDENTITY_INSERT dbo.Tasks ON;
--     INSERT INTO dbo.Tasks (
--         Id,
--         Client,
--         Description,
--         AssigneeId,
--         EstimatedHours,
--         DueDate,
--         Priority,
--         Status,
--         SprintId,
--         CreatedAt
--     )
--     OUTPUT inserted.Id INTO @T (Id)
--     SELECT @T0 + n,
--            CONCAT('Test Client ', ((n - 1) % 8) + 1),
--            CONCAT('Test task description ', n),
--            @D0 + ((n - 1) % 10) + 1,
--            CAST (2 + (n % 15) * 1.25 AS DECIMAL (10, 2)),
--            DATEADD(DAY, n, CAST ('2026-10-15' AS DATETIME)),
--            ((n - 1) % 3) + 1,
--            (n - 1) % 4,
--            @S0 + ((n - 1) % 5) + 1,
--            GETUTCDATE()
--     FROM   (VALUES (1), (2), (3), (4), (5), (6), (7), (8), (9), (10), (11), (12), (13), (14), (15), (16), (17), (18), (19), (20), (21), (22), (23), (24), (25), (26), (27), (28), (29), (30), (31), (32), (33), (34), (35)) AS v(n);
--     SET IDENTITY_INSERT dbo.Tasks OFF;
--     -- 4. Insert 50 time entries
--     SET IDENTITY_INSERT dbo.TimeEntries ON;
--     INSERT INTO dbo.TimeEntries (
--         Id,
--         TaskId,
--         DeveloperId,
--         DurationHours,
--         WorkDate,
--         Note,
--         CreatedAt
--     )
--     OUTPUT inserted.Id INTO @E (Id)
--     SELECT @E0 + n,
--            @T0 + ((n - 1) % 35) + 1,
--            @D0 + ((n - 1) % 10) + 1,
--            CAST (0.5 + ((n - 1) % 8) * 0.5 AS DECIMAL (10, 2)),
--            DATEADD(DAY, n - 1, CAST ('2026-10-01' AS DATETIME)),
--            CONCAT('Test work log ', n),
--            GETUTCDATE()
--     FROM   (VALUES (1), (2), (3), (4), (5), (6), (7), (8), (9), (10), (11), (12), (13), (14), (15), (16), (17), (18), (19), (20), (21), (22), (23), (24), (25), (26), (27), (28), (29), (30), (31), (32), (33), (34), (35), (36), (37), (38), (39), (40), (41), (42), (43), (44), (45), (46), (47), (48), (49), (50)) AS v(n);
--     SET IDENTITY_INSERT dbo.TimeEntries OFF;
--     -- 5. Validation des enregistrements
--     SELECT 'Developers' AS TableName,
--            COUNT(*) AS InsertedRecords
--     FROM   @D
--     UNION ALL
--     SELECT 'Sprints',
--            COUNT(*)
--     FROM   @S
--     UNION ALL
--     SELECT 'Tasks',
--            COUNT(*)
--     FROM   @T
--     UNION ALL
--     SELECT 'TimeEntries',
--            COUNT(*)
--     FROM   @E
--     UNION ALL
--     SELECT 'TOTAL',
--            (SELECT COUNT(*)
--             FROM   @D) + (SELECT COUNT(*)
--                           FROM   @S) + (SELECT COUNT(*)
--                                         FROM   @T) + (SELECT COUNT(*)
--                                                       FROM   @E);
--     COMMIT TRANSACTION;
--     PRINT 'SUCCESS: 100 sample records saved to DevTeamDb.';
-- END TRY
-- BEGIN CATCH
--     IF XACT_STATE() <> 0
--         ROLLBACK;
--     -- Sécurité pour désactiver IDENTITY_INSERT en cas d'erreur
--     BEGIN TRY
--         SET IDENTITY_INSERT dbo.Developers OFF;
--     END TRY
--     BEGIN CATCH
--     END CATCH
--     BEGIN TRY
--         SET IDENTITY_INSERT dbo.Sprints OFF;
--     END TRY
--     BEGIN CATCH
--     END CATCH
--     BEGIN TRY
--         SET IDENTITY_INSERT dbo.Tasks OFF;
--     END TRY
--     BEGIN CATCH
--     END CATCH
--     BEGIN TRY
--         SET IDENTITY_INSERT dbo.TimeEntries OFF;
--     END TRY
--     BEGIN CATCH
--     END CATCH
--     SELECT ERROR_NUMBER() AS ErrorNumber,
--            ERROR_MESSAGE() AS ErrorMessage,
--            ERROR_LINE() AS ErrorLine;
--     THROW;
-- END CATCH
/*
    Project : DevTeam Task Manager
    Script  : Seed-DevTeamDb.sql
    Purpose : Repeatable development/test data seeding
    Database: DevTeamDb

    Safety:
      - Never truncates or deletes existing records.
      - Does not manually assign identity IDs.
      - Uses explicit transaction handling.
      - Uses stable seed identifiers to avoid duplicate records.
      - Intended for a development/test database.
*/
USE [DevTeamDb];


GO
SET NOCOUNT ON;

SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;
    ------------------------------------------------------------
    -- 1. DEFINE SEED DATA
    ------------------------------------------------------------
    DECLARE @DeveloperSeed TABLE (
        Name  NVARCHAR (200) NOT NULL,
        Email NVARCHAR (320) NOT NULL PRIMARY KEY);
    INSERT  INTO @DeveloperSeed (
        Name,
        Email
    )
    VALUES                      ('Seed Developer 01', 'seed.dev01@devteam.local'),
                                ('Seed Developer 02', 'seed.dev02@devteam.local'),
                                ('Seed Developer 03', 'seed.dev03@devteam.local'),
                                ('Seed Developer 04', 'seed.dev04@devteam.local'),
                                ('Seed Developer 05', 'seed.dev05@devteam.local'),
                                ('Seed Developer 06', 'seed.dev06@devteam.local'),
                                ('Seed Developer 07', 'seed.dev07@devteam.local'),
                                ('Seed Developer 08', 'seed.dev08@devteam.local'),
                                ('Seed Developer 09', 'seed.dev09@devteam.local'),
                                ('Seed Developer 10', 'seed.dev10@devteam.local');
    DECLARE @SprintSeed TABLE (
        Name      NVARCHAR (200) NOT NULL PRIMARY KEY,
        StartDate DATETIME       NOT NULL,
        EndDate   DATETIME       NOT NULL,
        Status    INT            NOT NULL);
    /*
       Confirm these status values against SprintStatus.cs:
       1 = Planned, 2 = Active, 3 = Closed.
    */
    INSERT  INTO @SprintSeed (
        Name,
        StartDate,
        EndDate,
        Status
    )
    VALUES                   ('Seed Sprint 01', '2026-10-01', '2026-10-14', 3),
                             ('Seed Sprint 02', '2026-10-15', '2026-10-28', 2),
                             ('Seed Sprint 03', '2026-10-29', '2026-11-11', 1),
                             ('Seed Sprint 04', '2026-11-12', '2026-11-25', 1),
                             ('Seed Sprint 05', '2026-11-26', '2026-12-09', 1);
    ------------------------------------------------------------
    -- 2. INSERT MISSING DEVELOPERS
    ------------------------------------------------------------
    INSERT INTO dbo.Developers (
        Name,
        Email
    )
    SELECT s.Name,
           s.Email
    FROM   @DeveloperSeed AS s
    WHERE  NOT EXISTS (SELECT 1
                       FROM   dbo.Developers AS d
                       WHERE  d.Email = s.Email);
    ------------------------------------------------------------
    -- 3. RESOLVE DEVELOPER IDS
    ------------------------------------------------------------
    DECLARE @Developers TABLE (
        SeedNumber INT            NOT NULL PRIMARY KEY,
        Id         INT            NOT NULL,
        Email      NVARCHAR (320) NOT NULL);
    INSERT INTO @Developers (
        SeedNumber,
        Id,
        Email
    )
    SELECT ROW_NUMBER() OVER (ORDER BY s.Email),
           d.Id,
           s.Email
    FROM   @DeveloperSeed AS s
           INNER JOIN
           dbo.Developers AS d
           ON d.Email = s.Email;
    ------------------------------------------------------------
    -- 4. INSERT MISSING SPRINTS
    ------------------------------------------------------------
    INSERT INTO dbo.Sprints (
        Name,
        StartDate,
        EndDate,
        Status
    )
    SELECT s.Name,
           s.StartDate,
           s.EndDate,
           s.Status
    FROM   @SprintSeed AS s
    WHERE  NOT EXISTS (SELECT 1
                       FROM   dbo.Sprints AS existing
                       WHERE  existing.Name = s.Name);
    ------------------------------------------------------------
    -- 5. RESOLVE SPRINT IDS
    ------------------------------------------------------------
    DECLARE @Sprints TABLE (
        SeedNumber INT            NOT NULL PRIMARY KEY,
        Id         INT            NOT NULL,
        Name       NVARCHAR (200) NOT NULL);
    INSERT INTO @Sprints (
        SeedNumber,
        Id,
        Name
    )
    SELECT ROW_NUMBER() OVER (ORDER BY s.Name),
           db.Id,
           s.Name
    FROM   @SprintSeed AS s
           INNER JOIN
           dbo.Sprints AS db
           ON db.Name = s.Name;
    DECLARE @ActiveSprintId AS INT;
    SELECT @ActiveSprintId = Id
    FROM   @Sprints
    WHERE  Name = 'Seed Sprint 02';
    IF @ActiveSprintId IS NULL
        THROW 50001, 'The seed active sprint could not be resolved.', 1; ------------------------------------------------------------
    -- 6. INSERT 35 TASKS WITHOUT DUPLICATING SEED RECORDS
    ------------------------------------------------------------
    WITH Numbers
    AS   (SELECT 1 AS n
          UNION ALL
          SELECT n + 1
          FROM   Numbers
          WHERE  n < 35)
    INSERT INTO dbo.Tasks (
        Client,
        Description,
        AssigneeId,
        EstimatedHours,
        DueDate,
        Priority,
        Status,
        SprintId,
        CreatedAt
    )
    SELECT CONCAT('Seed Client ', ((n - 1) % 8) + 1),
           CONCAT('Seed task description ', n),
           d.Id,
           CAST (2 + (n % 15) * 1.25 AS DECIMAL (10, 2)),
           DATEADD(DAY, n, CAST ('2026-10-15' AS DATETIME)),
           ((n - 1) % 3) + 1,
           (n - 1) % 4,
           (SELECT s.Id
            FROM   @Sprints AS s
            WHERE  s.SeedNumber = ((n - 1) % 5) + 1),
           GETUTCDATE()
    FROM   Numbers AS numbers
           INNER JOIN
           @Developers AS d
           ON d.SeedNumber = ((n - 1) % 10) + 1
    WHERE  NOT EXISTS (SELECT 1
                       FROM   dbo.Tasks AS existing
                       WHERE  existing.Description = CONCAT('Seed task description ', n)
                              AND existing.Client = CONCAT('Seed Client ', ((n - 1) % 8) + 1))
    OPTION (MAXRECURSION 100);
    ------------------------------------------------------------
    -- 7. RESOLVE TASK IDS
    ------------------------------------------------------------
    DECLARE @Tasks TABLE (
        SeedNumber INT NOT NULL PRIMARY KEY,
        Id         INT NOT NULL);
    INSERT INTO @Tasks (
        SeedNumber,
        Id
    )
    SELECT n.n,
           t.Id
    FROM   (SELECT 1 AS n
            UNION ALL
            SELECT n + 1
            FROM   (SELECT TOP (34) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
                    FROM   sys.all_objects) AS numbers
            WHERE  n < 35) AS n
           INNER JOIN
           dbo.Tasks AS t
           ON t.Description = CONCAT('Seed task description ', n.n)
              AND t.Client = CONCAT('Seed Client ', ((n.n - 1) % 8) + 1); ------------------------------------------------------------
    -- 8. INSERT 50 TIME ENTRIES WITHOUT DUPLICATES
    ------------------------------------------------------------
    WITH Numbers
    AS   (SELECT 1 AS n
          UNION ALL
          SELECT n + 1
          FROM   Numbers
          WHERE  n < 50)
    INSERT INTO dbo.TimeEntries (
        TaskId,
        DeveloperId,
        DurationHours,
        WorkDate,
        Note,
        CreatedAt
    )
    SELECT t.Id,
           d.Id,
           CAST (0.5 + ((n - 1) % 8) * 0.5 AS DECIMAL (10, 2)),
           DATEADD(DAY, n - 1, CAST ('2026-10-01' AS DATETIME)),
           CONCAT('Seed work log ', n),
           GETUTCDATE()
    FROM   Numbers AS numbers
           INNER JOIN
           @Tasks AS t
           ON t.SeedNumber = ((n - 1) % 35) + 1
           INNER JOIN
           @Developers AS d
           ON d.SeedNumber = ((n - 1) % 10) + 1
    WHERE  NOT EXISTS (SELECT 1
                       FROM   dbo.TimeEntries AS existing
                       WHERE  existing.Note = CONCAT('Seed work log ', n)
                              AND existing.TaskId = t.Id
                              AND existing.DeveloperId = d.Id)
    OPTION (MAXRECURSION 100);
    ------------------------------------------------------------
    -- 9. VALIDATE FINAL DATABASE COUNTS
    ------------------------------------------------------------
    SELECT 'Developers' AS TableName,
           COUNT(*) AS SeedRecords
    FROM   dbo.Developers
    WHERE  Email LIKE 'seed.dev%@devteam.local'
    UNION ALL
    SELECT 'Sprints',
           COUNT(*)
    FROM   dbo.Sprints
    WHERE  Name LIKE 'Seed Sprint %'
    UNION ALL
    SELECT 'Tasks',
           COUNT(*)
    FROM   dbo.Tasks
    WHERE  Description LIKE 'Seed task description %'
    UNION ALL
    SELECT 'TimeEntries',
           COUNT(*)
    FROM   dbo.TimeEntries
    WHERE  Note LIKE 'Seed work log %';
    COMMIT TRANSACTION;
    PRINT 'SUCCESS: Development seed data processed.';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK;
    SELECT ERROR_NUMBER() AS ErrorNumber,
           ERROR_MESSAGE() AS ErrorMessage,
           ERROR_LINE() AS ErrorLine;
    THROW;
END CATCH

USE [DevTeamDb];


-- GO
-- BEGIN TRY
--     BEGIN TRANSACTION;
--     DELETE dbo.TimeEntries;
--     DELETE dbo.Tasks;
--     DELETE dbo.Sprints;
--     DELETE dbo.Developers;
--     COMMIT TRANSACTION;
--     PRINT 'All table data deleted successfully.';
-- END TRY
-- BEGIN CATCH
--     IF @@TRANCOUNT > 0
--         ROLLBACK;
--     THROW;
-- END CATCH