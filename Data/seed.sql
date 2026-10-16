-- USE DevTeamDb;
-- GO
-- -- 1. Clear existing test data
-- DELETE TimeEntries;
-- DELETE Tasks;
-- DELETE Sprints;
-- DELETE Developers;
-- DBCC CHECKIDENT ('Developers', RESEED, 0);
-- DBCC CHECKIDENT ('Sprints', RESEED, 0);
-- DBCC CHECKIDENT ('Tasks', RESEED, 0);
-- DBCC CHECKIDENT ('TimeEntries', RESEED, 0);
-- -- 2. Insert Developers
-- INSERT  INTO Developers (
--     Name,
--     Email
-- )
-- VALUES                  ('ahmed', 'ahmed@CliniSys.tn'),
--                         ('Aymen Ben Salah', 'aymen.bensalah@CliniSys.tn'),
--                         ('Mariem Trabelsi', 'mariem.trabelsi@CliniSys.tn'),
--                         ('Ghazi Karray', 'ghazi.karray@CliniSys.tn');
-- -- 3. Insert Sprints
-- INSERT  INTO Sprints (
--     Name,
--     StartDate,
--     EndDate,
--     Status
-- )
-- VALUES               ('Sprint 1 - MVP Release', '2026-10-01', '2026-10-14', 2),
--                      ('Sprint 2 - AI Integration', '2026-10-15', '2026-10-28', 1),
--                      ('Sprint 3 - Performance Tuning', '2026-10-29', '2026-11-11', 1);
-- -- 4. Insert Tasks (Statuses: 1=À faire, 2=En cours, 3=Terminé | Priorities: 1=Basse, 2=Moyenne, 3=Haute, 4=Critique)
-- INSERT  INTO Tasks (
--     Client,
--     Description,
--     AssigneeId,
--     EstimatedHours,
--     DueDate,
--     Priority,
--     Status,
--     SprintId,
--     CreatedAt
-- )
-- VALUES             -- Sprint 1 Tasks
--                    ('Acme Corp', 'Implement authentication and JWT tokens', 1, 8.0, '2026-10-05', 3, 3, 1, GETDATE()),
--                    ('Acme Corp', 'Fix payment gateway timeout issue', 2, 6.5, '2026-10-06', 4, 2, 1, GETDATE()),
--                    ('Tunisie Telecom', 'Optimize SQL Server query performance indices', 1, 12.0, '2026-10-10', 3, 2, 1, GETDATE()),
--                    ('Beta Solutions', 'Design customer onboarding wireframes', 3, 5.0, '2026-10-08', 2, 3, 1, GETDATE()),
--                    ('Beta Solutions', 'Setup CI/CD pipeline with GitHub Actions', 4, 10.0, '2026-10-12', 4, 1, 1, GETDATE()),
--                    -- Sprint 2 Tasks
--                    ('Global Logistics', 'Container tracking API integration', 2, 16.0, '2026-10-20', 3, 1, 2, GETDATE()),
--                    ('Global Logistics', 'Generate PDF monthly billing reports', 3, 8.0, '2026-10-22', 2, 1, 2, GETDATE()),
--                    ('Sfax Retail', 'E-commerce shopping cart persistence bug', 1, 4.0, '2026-10-18', 4, 1, 2, GETDATE()),
--                    -- Sprint 3 Tasks
--                    ('Medina Craft', 'Setup multilingual Arabic-French UI toggle', 3, 7.5, '2026-11-02', 1, 1, 3, GETDATE()),
--                    ('Medina Craft', 'Configure Redis output caching layer', 4, 14.0, '2026-11-05', 3, 1, 3, GETDATE());
-- -- 5. Insert Time Entries (Simulating time spent and budget overruns for testing reports)
-- INSERT  INTO TimeEntries (
--     TaskId,
--     DeveloperId,
--     WorkDate,
--     DurationHours,
--     Note,
--     CreatedAt
-- )
-- VALUES                   (1, 1, '2026-10-02', 4.0, 'Initial token generation setup', GETDATE()),
--                          (1, 1, '2026-10-03', 4.5, 'Refined claims and expiration handling', GETDATE()),
--                          (2, 2, '2026-10-04', 5.0, 'Investigated gateway logs', GETDATE()),
--                          (3, 1, '2026-10-05', 14.0, 'Heavy query tuning on execution plans', GETDATE()),
--                          (4, 3, '2026-10-02', 4.0, 'Figma wireframes complete', GETDATE());
USE DevTeamDb;


GO
-- 1. Nettoyage complet des données (Respect des contraintes de clés étrangères)
DELETE TimeEntries;

DELETE Tasks;

DELETE Sprints;

DELETE Developers;

-- 2. Réinitialisation des compteurs d'auto-incrémentation (IDENTITY)
DBCC CHECKIDENT ('TimeEntries', RESEED, 0);

DBCC CHECKIDENT ('Tasks', RESEED, 0);

DBCC CHECKIDENT ('Sprints', RESEED, 0);

DBCC CHECKIDENT ('Developers', RESEED, 0);

-- 3. Insertion des Développeurs (Équipe CliniSys + Wassim Yaich)
INSERT  INTO Developers (
    Name,
    Email
)
VALUES                  ('Wassim Yaich', 'wassim.yaich@CliniSys.tn'),
                        ('Ahmed', 'ahmed@CliniSys.tn'),
                        ('Aymen Ben Salah', 'aymen.bensalah@CliniSys.tn'),
                        ('Mariem Trabelsi', 'mariem.trabelsi@CliniSys.tn'),
                        ('Ghazi Karray', 'ghazi.karray@CliniSys.tn');

-- 4. Insertion des Sprints (Alignés sur le découpage Agile du projet)
-- (Status: 1 = Planifié, 2 = En cours, 3 = Terminé)
INSERT  INTO Sprints (
    Name,
    StartDate,
    EndDate,
    Status
)
VALUES               ('Sprint 1 — Fondation Architecture & Modélisation', '2026-10-01', '2026-10-05', 3),
                     ('Sprint 2 — Persistance & Migration SQL Server', '2026-10-06', '2026-10-10', 3),
                     ('Sprint 3 — Logique Métier & Optimisations', '2026-10-11', '2026-10-15', 2);

-- 5. Insertion des Tâches attribuées selon les Sprints du projet
-- (Status: 1=À faire, 2=En cours, 3=Terminé | Priorities: 1=Basse, 2=Moyenne, 3=Haute, 4=Critique)
INSERT  INTO Tasks (
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
VALUES             -- -------------------------------------------------------------
                   -- SPRINT 1 : Fondation Architecture & Modélisation (Terminé)
                   -- -------------------------------------------------------------
                   ('CliniSys', 'Conception de la structure de l API ASP.NET Core et architecture DTOs', 1, 8.0, '2026-10-02', 4, 3, 1, GETDATE()),
                   ('CliniSys', 'Modélisation du domaine (entités Developer, TaskItem, Sprint, TimeEntry)', 1, 6.0, '2026-10-03', 3, 3, 1, GETDATE()),
                   ('CliniSys', 'Configuration initiale du AppDbContext et de l Injection de Dépendances', 1, 4.0, '2026-10-04', 3, 3, 1, GETDATE()),
                   ('Acme Corp', 'Implémentation de l authentification et sécurisation JWT', 2, 8.0, '2026-10-05', 3, 3, 1, GETDATE()),
                   -- -------------------------------------------------------------
                   -- SPRINT 2 : Persistance & Migration SQL Server (Terminé)
                   -- -------------------------------------------------------------
                   ('CliniSys', 'Migration de PostgreSQL/Neon.tech vers Microsoft SQL Server (DevTeamDb)', 1, 10.0, '2026-10-07', 4, 3, 2, GETDATE()),
                   ('CliniSys', 'Configuration des relations Fluent API et règles de suppression DeleteBehavior', 1, 6.0, '2026-10-08', 3, 3, 2, GETDATE()),
                   ('CliniSys', 'Exécution et validation des migrations EF Core (dotnet ef database update)', 1, 4.0, '2026-10-09', 4, 3, 2, GETDATE()),
                   ('Tunisie Telecom', 'Résolution des conflits de ports IIS/Kestrel et nettoyage du packaging NuGet', 3, 5.0, '2026-10-10', 2, 3, 2, GETDATE()),
                   -- -------------------------------------------------------------
                   -- SPRINT 3 : Logique Métier & Optimisations (En cours)
                   -- -------------------------------------------------------------
                   ('CliniSys', 'Déploiement des contrôleurs RESTful et endpoints paginés Skip/Take', 1, 8.0, '2026-10-12', 4, 3, 3, GETDATE()),
                   ('CliniSys', 'Optimisation des performances de lecture seule via la directive AsNoTracking', 1, 4.0, '2026-10-13', 3, 3, 3, GETDATE()),
                   ('CliniSys', 'Mise en place du filtrage textuel et du tri dynamique sur les arbres IQueryable', 1, 6.0, '2026-10-14', 3, 2, 3, GETDATE()),
                   ('Beta Solutions', 'Validation globale des tests d intégration API et recette technique', 4, 12.0, '2026-10-15', 3, 1, 3, GETDATE());

-- 6. Insertion des Feuillets de Temps (TimeEntries) enregistrés durant les 72h
INSERT  INTO TimeEntries (
    TaskId,
    DeveloperId,
    WorkDate,
    DurationHours,
    Note,
    CreatedAt
)
VALUES                   -- Sprint 1 (Wassim Yaich & Équipe)
                         (1, 1, '2026-10-01', 8.0, 'Mise en place de l architecture propre ASP.NET Core et DTOs', GETDATE()),
                         (2, 1, '2026-10-02', 6.0, 'Création des entités métiers et propriétés de navigation', GETDATE()),
                         (4, 2, '2026-10-03', 8.0, 'Configuration des tokens JWT et contrôleur d auth', GETDATE()),
                         -- Sprint 2 (Wassim Yaich & Équipe)
                         (5, 1, '2026-10-06', 10.0, 'Bascule du provider EF Core vers SQL Server et mise à jour de Program.cs', GETDATE()),
                         (6, 1, '2026-10-07', 6.0, 'Mapping Fluent API OnModelCreating et clés étrangères', GETDATE()),
                         (7, 1, '2026-10-08', 4.0, 'Migration initiale exécutée avec succès sur DevTeamDb', GETDATE()),
                         -- Sprint 3 (Wassim Yaich & Équipe)
                         (9, 1, '2026-10-11', 8.0, 'Développement du contrôleur des tâches avec réponse paginée PagedResponse', GETDATE()),
                         (10, 1, '2026-10-12', 4.0, 'Intégration d AsNoTracking sur l ensemble des requêtes de consultation', GETDATE()),
                         (11, 1, '2026-10-13', 6.0, 'Implémentation des filtres de recherche SearchTerm et tri dynamique', GETDATE());