/* =====================================================================
   DevTeam Task Manager - Jeu de données réaliste
   ATTENTION : ce script VIDE les tables TimeEntries, Tasks, Sprints
   et Developers avant de les remplir. Toutes les données actuelles
   seront perdues.
   Base cible : DevTeamDb (changez la ligne USE si vous utilisez Docker : DevTeamTaskDb)
   Valeurs des énumérations :
     Status   : 1 = À faire, 2 = En cours, 3 = Terminé
     Priority : 1 = Basse, 2 = Moyenne, 3 = Haute, 4 = Critique
     SprintStatus : 1 = Planifié, 2 = Actif, 3 = Clôturé
   ===================================================================== */
USE DevTeamDb;


GO
SET NOCOUNT ON;

SET XACT_ABORT ON;

BEGIN TRANSACTION;

-- 1. Nettoyage (ordre imposé par les clés étrangères RESTRICT)
DELETE TimeEntries;

DELETE Tasks;

DELETE Sprints;

DELETE Developers;

DBCC CHECKIDENT ('TimeEntries', RESEED, 0)
    WITH NO_INFOMSGS;

DBCC CHECKIDENT ('Tasks', RESEED, 0)
    WITH NO_INFOMSGS;

DBCC CHECKIDENT ('Sprints', RESEED, 0)
    WITH NO_INFOMSGS;

DBCC CHECKIDENT ('Developers', RESEED, 0)
    WITH NO_INFOMSGS;

-- 2. Développeurs
SET IDENTITY_INSERT Developers ON;

INSERT  INTO Developers (
    Id,
    Name,
    Email
)
VALUES                  (1, N'Wassim Yaich', N'wassim@devteam.local'),
                        (2, N'Sarah Ben Ali', N'sarah@devteam.local'),
                        (3, N'Mehdi Trabelsi', N'mehdi@devteam.local'),
                        (4, N'Ines Jlassi', N'ines@devteam.local'),
                        (5, N'Karim Mansouri', N'karim@devteam.local'),
                        (6, N'Amira Gharbi', N'amira@devteam.local');

SET IDENTITY_INSERT Developers OFF;

-- 3. Sprints
SET IDENTITY_INSERT Sprints ON;

INSERT  INTO Sprints (
    Id,
    Name,
    StartDate,
    EndDate,
    Status
)
VALUES               (1, N'Sprint 1 - Fondations', '2026-09-14', '2026-09-25', 3),
                     (2, N'Sprint 2 - Gestion des tâches', '2026-09-28', '2026-10-09', 3),
                     (3, N'Sprint 3 - Kanban et sprints', '2026-10-12', '2026-10-23', 2),
                     (4, N'Sprint 4 - Rapports et finitions', '2026-10-26', '2026-11-06', 1);

SET IDENTITY_INSERT Sprints OFF;

-- 4. Tâches
SET IDENTITY_INSERT Tasks ON;

INSERT  INTO Tasks (
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
VALUES             -- Sprint 1 (clôturé, tout terminé)
                   (1, N'CliniSys', N'Mise en place de la solution .NET et de la base SQL Server', 1, 16, '2026-09-18', 3, 3, 1, '2026-09-10'),
                   (2, N'CliniSys', N'Modélisation des entités et migrations EF Core', 2, 20, '2026-09-22', 3, 3, 1, '2026-09-10'),
                   (3, N'Medina Shop', N'Maquette de la page catalogue produits', 4, 14, '2026-09-23', 2, 3, 1, '2026-09-10'),
                   (4, N'Tunisie Logistics', N'Import CSV des tournées de livraison', 3, 24, '2026-09-25', 2, 3, 1, '2026-09-10'),
                   (5, N'EduPlus Tunis', N'Authentification des formateurs (JWT)', 5, 18, '2026-09-24', 4, 3, 1, '2026-09-10'),
                   -- Sprint 2 (clôturé, une tâche non terminée reportable)
                   (6, N'CliniSys', N'API CRUD des rendez-vous patients', 1, 28, '2026-10-02', 3, 3, 2, '2026-09-24'),
                   (7, N'AgriTech Cap Bon', N'Tableau de bord des capteurs d''irrigation', 6, 30, '2026-10-06', 2, 3, 2, '2026-09-24'),
                   (8, N'Sfax Énergie', N'Calcul de la consommation mensuelle par site', 2, 22, '2026-10-05', 3, 3, 2, '2026-09-24'),
                   (9, N'Medina Shop', N'Panier d''achat et validation de commande', 4, 26, '2026-10-08', 3, 3, 2, '2026-09-24'),
                   (10, N'Tunisie Logistics', N'Suivi des colis en temps réel', 3, 32, '2026-10-09', 4, 2, 2, '2026-09-24'),
                   (11, N'EduPlus Tunis', N'Export PDF des bulletins de notes', 5, 12, '2026-10-09', 1, 3, 2, '2026-09-24'),
                   -- Sprint 3 (actif)
                   (12, N'CliniSys', N'Gestion des droits par rôle', 1, 24, '2026-10-16', 3, 2, 3, '2026-10-08'),
                   (13, N'CliniSys', N'Notifications e-mail de rappel de rendez-vous', 1, 16, '2026-10-21', 2, 1, 3, '2026-10-08'),
                   (14, N'Sfax Énergie', N'Alertes de dépassement de seuil de consommation', 1, 16, '2026-10-23', 2, 1, 3, '2026-10-08'),
                   (15, N'Medina Shop', N'Filtres et recherche de produits', 2, 20, '2026-10-14', 2, 3, 3, '2026-10-08'),
                   (16, N'Medina Shop', N'Paiement en ligne (environnement de test)', 2, 28, '2026-10-22', 4, 2, 3, '2026-10-08'),
                   (17, N'Tunisie Logistics', N'Optimisation des tournées de livraison', 3, 40, '2026-10-23', 3, 2, 3, '2026-10-08'),
                   (18, N'Tunisie Logistics', N'Génération des bordereaux de livraison', 3, 30, '2026-10-23', 2, 1, 3, '2026-10-08'),
                   (19, N'AgriTech Cap Bon', N'Historique des mesures et graphiques', 4, 24, '2026-10-20', 2, 2, 3, '2026-10-08'),
                   (20, N'AgriTech Cap Bon', N'Alerte gel et sécheresse', 4, 16, '2026-10-23', 3, 1, 3, '2026-10-08'),
                   (21, N'EduPlus Tunis', N'Espace étudiant : consultation des notes', 5, 20, '2026-10-14', 2, 3, 3, '2026-10-08'),
                   (22, N'EduPlus Tunis', N'Forum de questions-réponses', 5, 24, '2026-10-23', 1, 1, 3, '2026-10-08'),
                   (23, N'CliniSys', N'Tableau de bord des statistiques médecins', 6, 18, '2026-10-22', 2, 1, 3, '2026-10-08'),
                   (24, N'Sfax Énergie', N'Export Excel des relevés de consommation', 6, 12, '2026-10-21', 1, 1, 3, '2026-10-08'),
                   -- Sprint 4 (planifié)
                   (25, N'CliniSys', N'Rapport PDF de facturation', 1, 20, '2026-11-03', 2, 1, 4, '2026-10-12'),
                   (26, N'Medina Shop', N'Gestion des retours produits', 2, 24, '2026-11-05', 2, 1, 4, '2026-10-12'),
                   (27, N'Tunisie Logistics', N'Tableau de bord des performances des livreurs', 3, 28, '2026-11-06', 3, 1, 4, '2026-10-12'),
                   (28, N'AgriTech Cap Bon', N'Application mobile : consultation hors-ligne', 6, 32, '2026-11-06', 1, 1, 4, '2026-10-12'),
                   -- Backlog (sans sprint)
                   (29, N'Sfax Énergie', N'Prévision de consommation (modèle statistique simple)', 2, 40, '2026-11-20', 1, 1, NULL, '2026-10-14'),
                   (30, N'EduPlus Tunis', N'Certificats de réussite en ligne', 5, 16, '2026-11-13', 2, 1, NULL, '2026-10-14'),
                   (31, N'CliniSys', N'Sauvegarde automatique et restauration des données', 1, 12, '2026-11-10', 4, 1, NULL, '2026-10-14'),
                   (32, N'Medina Shop', N'Optimisation SEO des pages produits', 4, 14, '2026-11-18', 1, 1, NULL, '2026-10-14');

SET IDENTITY_INSERT Tasks OFF;

-- 5. Imputations de temps (jamais plus de 8 h par entrée, pas de week-end, pas de jour férié le 15/10)
INSERT INTO TimeEntries (
    TaskId,
    DeveloperId,
    WorkDate,
    DurationHours,
    Note,
    CreatedAt
)
SELECT v.TaskId,
       v.DeveloperId,
       CAST (v.WorkDate AS DATETIME2),
       v.Hours,
       v.Note,
       DATEADD(HOUR, 17, CAST (v.WorkDate AS DATETIME2))
FROM   (VALUES -- Sprint 1
       (1, 1, '2026-09-14', 7.0, N'Création de la solution et des projets'), (1, 1, '2026-09-15', 6.0, N'Configuration SQL Server et chaîne de connexion'), (1, 1, '2026-09-16', 5.0, N'Docker compose et premiers tests'), (2, 2, '2026-09-15', 7.0, N'Entités et relations'), (2, 2, '2026-09-16', 7.0, N'Première migration'), (2, 2, '2026-09-17', 5.0, N'Données initiales et index'), (3, 4, '2026-09-18', 6.0, N'Maquette desktop'), (3, 4, '2026-09-21', 6.0, N'Version mobile de la maquette'), (4, 3, '2026-09-17', 7.0, N'Lecture et validation du fichier CSV'), (4, 3, '2026-09-18', 7.0, N'Import en base par lots'), (4, 3, '2026-09-21', 6.0, N'Gestion des erreurs de format'), (4, 1, '2026-09-22', 3.0, N'Revue de code et aide sur l''import'), (5, 5, '2026-09-16', 7.0, N'Génération et validation des jetons'), (5, 5, '2026-09-17', 7.0, N'Rafraîchissement des jetons'), (5, 5, '2026-09-22', 4.0, N'Correction des cas limites'), (5, 5, '2026-09-23', 3.0, N'Tests d''intégration'), -- Sprint 2
       (6, 1, '2026-09-28', 7.0, N'Endpoints de lecture'), (6, 1, '2026-09-29', 7.0, N'Création et modification'), (6, 1, '2026-09-30', 7.0, N'Validation des chevauchements'), (6, 1, '2026-10-01', 6.0, N'Tests et documentation Swagger'), (7, 6, '2026-09-28', 7.0, N'Structure du tableau de bord'), (7, 6, '2026-09-29', 7.0, N'Graphiques des capteurs'), (7, 6, '2026-09-30', 7.0, N'Rafraîchissement automatique'), (7, 6, '2026-10-01', 7.0, N'Filtres par parcelle'), (7, 6, '2026-10-02', 4.0, N'Corrections après démonstration client'), (8, 2, '2026-09-30', 6.0, N'Agrégation mensuelle'), (8, 2, '2026-10-01', 7.0, N'Calcul par site'), (8, 2, '2026-10-02', 7.0, N'Tests des calculs'), (9, 4, '2026-10-01', 7.0, N'Panier côté serveur'), (9, 4, '2026-10-02', 7.0, N'Validation de commande'), (9, 4, '2026-10-05', 7.0, N'Gestion du stock'), (9, 4, '2026-10-06', 6.0, N'Correction de bugs de quantité'), (10, 3, '2026-09-28', 7.0, N'Modèle de suivi des colis'), (10, 3, '2026-09-29', 7.0, N'Mise à jour des positions'), (10, 3, '2026-09-30', 7.0, N'Écran de suivi'), (10, 3, '2026-10-01', 6.0, N'Notifications de statut'), (10, 3, '2026-10-02', 3.0, N'Tests de charge'), (10, 3, '2026-10-05', 5.0, N'Problèmes de synchronisation'), (11, 5, '2026-10-05', 6.0, N'Mise en page du bulletin'), (11, 5, '2026-10-06', 5.0, N'Génération PDF'), -- Sprint 3 (en cours : le 15/10 est férié, le 17 et 18/10 sont un week-end)
       (12, 1, '2026-10-12', 7.0, N'Modèle des rôles'), (12, 1, '2026-10-13', 7.0, N'Filtres d''autorisation sur les endpoints'), (12, 1, '2026-10-14', 4.0, N'Tests des droits'), (15, 2, '2026-10-12', 6.0, N'Recherche par nom'), (15, 2, '2026-10-13', 7.0, N'Filtres par catégorie et prix'), (15, 2, '2026-10-14', 5.0, N'Pagination et tests'), (16, 2, '2026-10-14', 2.0, N'Lecture de la documentation du prestataire'), (16, 2, '2026-10-16', 7.0, N'Intégration du paiement de test'), (17, 3, '2026-10-12', 7.0, N'Algorithme de regroupement'), (17, 3, '2026-10-13', 7.0, N'Calcul des distances'), (17, 3, '2026-10-14', 7.0, N'Optimisation de l''ordre des arrêts'), (17, 3, '2026-10-16', 7.0, N'Réglage des contraintes horaires'), (19, 4, '2026-10-13', 6.0, N'Stockage de l''historique'), (19, 4, '2026-10-14', 6.0, N'Courbes par période'), (19, 4, '2026-10-16', 5.0, N'Comparaison entre capteurs'), (21, 5, '2026-10-12', 7.0, N'Page des notes'), (21, 5, '2026-10-13', 7.0, N'Moyennes par matière'), (21, 5, '2026-10-14', 6.0, N'Tests et corrections')) AS v(TaskId, DeveloperId, WorkDate, Hours, Note);

COMMIT TRANSACTION;

-- 6. Vérifications
SELECT 'Developers' AS [Table],
       COUNT(*) AS Nb
FROM   Developers
UNION ALL
SELECT 'Sprints',
       COUNT(*)
FROM   Sprints
UNION ALL
SELECT 'Tasks',
       COUNT(*)
FROM   Tasks
UNION ALL
SELECT 'TimeEntries',
       COUNT(*)
FROM   TimeEntries;

-- Tâches en dépassement (heures passées > estimation) : attendu = 5 tâches (1, 5, 7, 9, 10)
SELECT   t.Id,
         t.Client,
         t.EstimatedHours,
         SUM(te.DurationHours) AS Logged
FROM     Tasks AS t
         INNER JOIN
         TimeEntries AS te
         ON te.TaskId = t.Id
GROUP BY t.Id, t.Client, t.EstimatedHours
HAVING   SUM(te.DurationHours) > t.EstimatedHours
ORDER BY t.Id;