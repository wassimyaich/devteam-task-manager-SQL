USE DevTeamDb;


GO
SET NOCOUNT ON;

SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;
    -- Tables temporaires pour stocker les ID insérés
    DECLARE @D TABLE (
        Id INT PRIMARY KEY);
    DECLARE @S TABLE (
        Id INT PRIMARY KEY);
    DECLARE @T TABLE (
        Id INT PRIMARY KEY);
    DECLARE @E TABLE (
        Id INT PRIMARY KEY);
    -- Récupération des max ID actuels pour éviter les conflits
    DECLARE @D0 AS INT = ISNULL((SELECT MAX(Id)
                                 FROM   dbo.Developers), 0);
    DECLARE @S0 AS INT = ISNULL((SELECT MAX(Id)
                                 FROM   dbo.Sprints), 0);
    DECLARE @T0 AS INT = ISNULL((SELECT MAX(Id)
                                 FROM   dbo.Tasks), 0);
    DECLARE @E0 AS INT = ISNULL((SELECT MAX(Id)
                                 FROM   dbo.TimeEntries), 0);
    -- 1. Insert 10 developers
    SET IDENTITY_INSERT dbo.Developers ON;
    INSERT INTO dbo.Developers (
        Id,
        Name,
        Email
    )
    OUTPUT inserted.Id INTO @D (Id)
    SELECT @D0 + n,
           CONCAT('Test Developer ', n),
           CONCAT('test', @D0 + n, '@devteam.local')
    FROM   (VALUES (1), (2), (3), (4), (5), (6), (7), (8), (9), (10)) AS v(n);
    SET IDENTITY_INSERT dbo.Developers OFF;
    -- 2. Insert 5 sprints (Statut : 1 = Planned, 2 = Active, 3 = Closed)
    SET IDENTITY_INSERT dbo.Sprints ON;
    INSERT INTO dbo.Sprints (
        Id,
        Name,
        StartDate,
        EndDate,
        Status
    )
    OUTPUT inserted.Id INTO @S (Id)
    SELECT @S0 + n,
           CONCAT('Test Sprint ', n),
           DATEADD(DAY, (n - 1) * 14, CAST ('2026-10-01' AS DATETIME)),
           DATEADD(DAY, (n - 1) * 14 + 13, CAST ('2026-10-01' AS DATETIME)),
           CASE WHEN n = 1 THEN 3 ELSE 2 END -- Le sprint 1 est fermé (3), les autres sont actifs (2)
    FROM   (VALUES (1), (2), (3), (4), (5)) AS v(n);
    SET IDENTITY_INSERT dbo.Sprints OFF;
    -- 3. Insert 35 tasks
    SET IDENTITY_INSERT dbo.Tasks ON;
    INSERT INTO dbo.Tasks (
        Id,
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
    OUTPUT inserted.Id INTO @T (Id)
    SELECT @T0 + n,
           CONCAT('Test Client ', ((n - 1) % 8) + 1),
           CONCAT('Test task description ', n),
           @D0 + ((n - 1) % 10) + 1,
           CAST (2 + (n % 15) * 1.25 AS DECIMAL (10, 2)),
           DATEADD(DAY, n, CAST ('2026-10-15' AS DATETIME)),
           ((n - 1) % 3) + 1,
           (n - 1) % 4,
           @S0 + ((n - 1) % 5) + 1,
           GETUTCDATE()
    FROM   (VALUES (1), (2), (3), (4), (5), (6), (7), (8), (9), (10), (11), (12), (13), (14), (15), (16), (17), (18), (19), (20), (21), (22), (23), (24), (25), (26), (27), (28), (29), (30), (31), (32), (33), (34), (35)) AS v(n);
    SET IDENTITY_INSERT dbo.Tasks OFF;
    -- 4. Insert 50 time entries
    SET IDENTITY_INSERT dbo.TimeEntries ON;
    INSERT INTO dbo.TimeEntries (
        Id,
        TaskId,
        DeveloperId,
        DurationHours,
        WorkDate,
        Note,
        CreatedAt
    )
    OUTPUT inserted.Id INTO @E (Id)
    SELECT @E0 + n,
           @T0 + ((n - 1) % 35) + 1,
           @D0 + ((n - 1) % 10) + 1,
           CAST (0.5 + ((n - 1) % 8) * 0.5 AS DECIMAL (10, 2)),
           DATEADD(DAY, n - 1, CAST ('2026-10-01' AS DATETIME)),
           CONCAT('Test work log ', n),
           GETUTCDATE()
    FROM   (VALUES (1), (2), (3), (4), (5), (6), (7), (8), (9), (10), (11), (12), (13), (14), (15), (16), (17), (18), (19), (20), (21), (22), (23), (24), (25), (26), (27), (28), (29), (30), (31), (32), (33), (34), (35), (36), (37), (38), (39), (40), (41), (42), (43), (44), (45), (46), (47), (48), (49), (50)) AS v(n);
    SET IDENTITY_INSERT dbo.TimeEntries OFF;
    -- 5. Validation des enregistrements
    SELECT 'Developers' AS TableName,
           COUNT(*) AS InsertedRecords
    FROM   @D
    UNION ALL
    SELECT 'Sprints',
           COUNT(*)
    FROM   @S
    UNION ALL
    SELECT 'Tasks',
           COUNT(*)
    FROM   @T
    UNION ALL
    SELECT 'TimeEntries',
           COUNT(*)
    FROM   @E
    UNION ALL
    SELECT 'TOTAL',
           (SELECT COUNT(*)
            FROM   @D) + (SELECT COUNT(*)
                          FROM   @S) + (SELECT COUNT(*)
                                        FROM   @T) + (SELECT COUNT(*)
                                                      FROM   @E);
    COMMIT TRANSACTION;
    PRINT 'SUCCESS: 100 sample records saved to DevTeamDb.';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK;
    -- Sécurité pour désactiver IDENTITY_INSERT en cas d'erreur
    BEGIN TRY
        SET IDENTITY_INSERT dbo.Developers OFF;
    END TRY
    BEGIN CATCH
    END CATCH
    BEGIN TRY
        SET IDENTITY_INSERT dbo.Sprints OFF;
    END TRY
    BEGIN CATCH
    END CATCH
    BEGIN TRY
        SET IDENTITY_INSERT dbo.Tasks OFF;
    END TRY
    BEGIN CATCH
    END CATCH
    BEGIN TRY
        SET IDENTITY_INSERT dbo.TimeEntries OFF;
    END TRY
    BEGIN CATCH
    END CATCH
    SELECT ERROR_NUMBER() AS ErrorNumber,
           ERROR_MESSAGE() AS ErrorMessage,
           ERROR_LINE() AS ErrorLine;
    THROW;
END CATCH


-- USE [DevTeamDb];
-- GO
-- BEGIN TRY
--     BEGIN TRANSACTION;
--     DELETE FROM dbo.TimeEntries;
--     DELETE FROM dbo.Tasks;
--     DELETE FROM dbo.Sprints;
--     DELETE FROM dbo.Developers;
--     COMMIT TRANSACTION;
--     PRINT 'All table data deleted successfully.';
-- END TRY
-- BEGIN CATCH
--     IF @@TRANCOUNT > 0
--         ROLLBACK TRANSACTION;
--     THROW;
-- END CATCH;
-- GO