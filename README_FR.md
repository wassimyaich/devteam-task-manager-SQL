# DevTeam Task Manager

[English version](README.en.md)

Outil interne de gestion de tâches pour équipes de développement : centraliser les demandes clients, organiser les sprints avec un tableau Kanban et suivre le temps passé par les développeurs.

Projet réalisé dans le cadre d'un test technique (prototype fonctionnel).

## Sommaire

- [Fonctionnalités](#fonctionnalités)
- [Stack technique](#stack-technique)
- [Structure du projet](#structure-du-projet)
- [Prérequis](#prérequis)
- [Installation et lancement](#installation-et-lancement)
- [Lancement avec Docker](#lancement-avec-docker)
- [Données de démonstration](#données-de-démonstration)
- [Tests](#tests)
- [API REST](#api-rest)
- [Règles métier](#règles-métier)
- [Intégrité et sécurité des données](#intégrité-et-sécurité-des-données)
- [Limites connues](#limites-connues)
- [Pistes d'amélioration](#pistes-damélioration)

## Fonctionnalités

**Gestion des tâches**
- Création, consultation et modification d'une tâche : client, description, développeur affecté, estimation (en heures), échéance, priorité (Basse, Moyenne, Haute, Critique) et statut (À faire, En cours, Terminé).
- Liste paginée avec filtres par client, développeur, statut, priorité et sprint.
- Modification à la volée de l'estimation et de l'échéance directement dans la liste, sans ouvrir de formulaire (appel API transparent).

**Sprints et Kanban**
- Création d'un sprint (nom, dates) avec rattachement de tâches du backlog.
- Taux d'affectation par développeur affiché dès la création du sprint.
- Tableau Kanban à trois colonnes avec glisser-déposer : le changement de statut est enregistré immédiatement en base.
- Clôture d'un sprint.

**Suivi du temps et rapports**
- Imputation du temps passé sur une tâche, avec date et note.
- Rapport par tâche : estimation, temps total passé, historique des imputations, signalement du dépassement.
- Rapport par sprint : total estimé, total passé, charge par développeur et alerte de surcharge.

## Stack technique

| Couche | Technologies |
|---|---|
| Backend | .NET 10, ASP.NET Core Web API (contrôleurs), C# |
| Accès aux données | Entity Framework Core 10, migrations |
| Base de données | SQL Server |
| Frontend | HTML, CSS, JavaScript, jQuery 3.7, jQuery UI 1.13 (glisser-déposer), Bootstrap 5.3 |
| Documentation API | Swagger (Swashbuckle), disponible en développement |
| Tests | xUnit |
| Conteneurs | Docker et Docker Compose (API et SQL Server 2022) |

Tous les appels de l'interface vers l'API sont asynchrones (AJAX).

## Structure du projet

```
DevTeamTaskManager/
├── DevTeamTaskManager.Api/
│   ├── Controllers/      Tasks, Sprints, TimeEntries, Developers
│   ├── Entities/         TaskItem, Sprint, Developer, TimeEntry
│   ├── Enums/            Priority, Status, SprintStatus
│   ├── DTOs/             Objets d'échange et PagedResult<T>
│   ├── Data/             AppDbContext et scripts SQL
│   ├── Migrations/       Migrations EF Core
│   ├── wwwroot/          Interface (index.html)
│   └── Program.cs
├── DevTeamTaskManager.Tests/   Tests unitaires xUnit
├── docker-compose.yml
└── DevTeamTaskManager.slnx
```

## Prérequis

- [.NET 10 SDK](https://dotnet.microsoft.com/download)
- SQL Server (Express, LocalDB ou instance complète)
- Outil EF Core en ligne de commande : `dotnet tool install --global dotnet-ef`
- Optionnel : Docker Desktop

## Installation et lancement

1. Cloner le dépôt :

   ```bash
   git clone https://github.com/wassimyaich/devteam-task-manager-SQL.git
   cd devteam-task-manager-SQL
   ```

2. Vérifier la chaîne de connexion dans `DevTeamTaskManager.Api/appsettings.json` (clé `ConnectionStrings:DefaultConnection`). Par défaut :

   ```
   Server=localhost;Database=DevTeamDb;Trusted_Connection=True;TrustServerCertificate=True;
   ```

3. Créer la base et appliquer les migrations :

   ```bash
   cd DevTeamTaskManager.Api
   dotnet ef database update
   ```

   Les migrations sont également appliquées automatiquement au démarrage de l'application.

4. Lancer l'application :

   ```bash
   dotnet run
   ```

   - Interface : `http://localhost:5074` (voir `Properties/launchSettings.json` pour le port exact)
   - Swagger : `/swagger` (environnement Development)

## Lancement avec Docker

```bash
docker compose up --build
```

- L'interface est disponible sur `http://localhost:5074`.
- La base `DevTeamTaskDb` est créée au premier démarrage par les migrations. Si l'API démarre avant SQL Server, elle redémarre automatiquement jusqu'à ce que la base soit prête.
- Les identifiants de `docker-compose.yml` sont destinés au développement local uniquement. Pour tout autre usage, utilisez un fichier `.env` non versionné.

## Données de démonstration

Un jeu de données réaliste est fourni : 6 développeurs, 4 sprints (2 clôturés, 1 actif, 1 planifié), 32 tâches et 58 imputations de temps. Il permet de vérifier tous les cas métier : tâches en dépassement, développeur surchargé, backlog, tâche non terminée dans un sprint clôturé.

**Attention : le script vide d'abord les tables Developers, Sprints, Tasks et TimeEntries.**

```bash
sqlcmd -S localhost -d DevTeamDb -E -C -i DevTeamTaskManager.Api/Data/seed_real_data.sql
```

Pour Docker, remplacez la ligne `USE DevTeamDb;` du script par `USE DevTeamTaskDb;`.

## Tests

Depuis la racine de la solution :

```bash
dotnet test
```

Les tests appellent directement le calcul réel des jours ouvrés : week-end seul, jour unique, semaine contenant un jour férié, sprint à cheval sur deux années, dates inversées.

## API REST

| Méthode | Route | Description |
|---|---|---|
| GET | `/api/tasks` | Liste paginée, filtres `client`, `assigneeId`, `status`, `priority`, `sprintId`, `unassigned`, `pageNumber`, `pageSize` |
| GET | `/api/tasks/{id}` | Détail d'une tâche avec temps passé |
| GET | `/api/tasks/{id}/report` | Rapport estimation et temps passé |
| POST | `/api/tasks` | Création d'une tâche |
| PUT | `/api/tasks/{id}` | Modification complète |
| PATCH | `/api/tasks/{id}/inline` | Modification de l'estimation et/ou de l'échéance |
| PATCH | `/api/tasks/{id}/status` | Changement de statut (Kanban) |
| DELETE | `/api/tasks/{id}` | Suppression (409 si du temps a été imputé) |
| GET | `/api/sprints` | Liste des sprints avec nombre de tâches |
| GET | `/api/sprints/active` | Sprints non clôturés |
| POST | `/api/sprints` | Création d'un sprint, retourne le rapport de capacité |
| GET | `/api/sprints/{id}/capacity` | Rapport de capacité et taux d'affectation |
| PATCH | `/api/sprints/{id}/close` | Clôture d'un sprint |
| GET, POST, DELETE | `/api/timeentries` | Imputations de temps |
| GET | `/api/developers` | Liste des développeurs |
| GET | `/api/developers/search?term=` | Recherche (autocomplétion) |

Les énumérations sont échangées sous forme d'entiers :

| Énumération | Valeurs |
|---|---|
| Priority | 1 Basse, 2 Moyenne, 3 Haute, 4 Critique |
| Status | 1 À faire, 2 En cours, 3 Terminé |
| SprintStatus | 1 Planifié, 2 Actif, 3 Clôturé |

## Règles métier

**Jours ouvrés.** Les samedis et dimanches (`DayOfWeek`), les jours fériés civils tunisiens et les fêtes religieuses (calendrier Hijri) sont exclus. Les jours fériés sont calculés pour chaque année couverte par le sprint. Un sprint doit contenir au moins un jour ouvré.

**Capacité et affectation.**

```
capacité d'un développeur = jours ouvrés du sprint x 7 h
taux d'affectation        = heures estimées de ses tâches dans le sprint / capacité x 100
surchargé                 = heures estimées > capacité
```

Tous les développeurs apparaissent dans le rapport, y compris ceux sans tâche (0 %).

**Dépassement.** Une tâche ou un sprint est en dépassement quand le temps passé est strictement supérieur à l'estimation initiale.

**Imputations de temps.** Durée comprise entre 0,1 et 24 h, date non située dans le futur, et 24 h maximum par développeur et par jour.

**Clôture d'un sprint.** Les tâches restent rattachées au sprint clôturé, ce qui garde son rapport exact. Les tâches non terminées sont reportées en les affectant à un nouveau sprint. Une tâche ne peut pas être affectée à un sprint clôturé.

## Intégrité et sécurité des données

- Requêtes paramétrées par Entity Framework Core (pas de SQL concaténé).
- Validation en couches : annotations de données sur les DTO, validation automatique de `[ApiController]`, contrôles explicites dans les contrôleurs (existence du développeur et du sprint, sprint non clôturé, date valide).
- Suppression en cascade désactivée (`DeleteBehavior.Restrict`) entre tâches, développeurs et imputations. Une tâche ayant du temps imputé ne peut pas être supprimée.
- Index sur les colonnes filtrées (statut, priorité, client) et unicité de l'email des développeurs.
- Échappement systématique des valeurs affichées dans l'interface pour limiter les risques XSS.
- Requêtes de lecture en `AsNoTracking`, annulables via `CancellationToken`.

## Limites connues

- Pas d'authentification ni de gestion de rôles.
- Pas de contrôle de concurrence : en cas de modification simultanée, la dernière écriture l'emporte.
- Les fêtes religieuses sont calculées avec le calendrier Hijri et peuvent différer de un à deux jours de l'annonce officielle. Les jours fériés civils sont codés en dur.
- Les estimations sont saisies uniquement en heures.
- Les tests automatisés couvrent le calcul des jours ouvrés ; il n'y a pas encore de tests d'intégration.

## Pistes d'amélioration

1. Extraire la logique de capacité et de jours ouvrés dans un service dédié (`ISprintService`).
2. Rapport par sprint détaillé tâche par tâche.
3. Contrôle de concurrence optimiste (`RowVersion`).
4. Modification des imputations de temps.
5. Utiliser `DateOnly` pour les dates sans heure.
6. Tests d'intégration (`WebApplicationFactory`, SQLite ou Testcontainers).
7. Authentification JWT et rôles.
8. Contraintes `CHECK` en base sur le statut et la priorité.

## Auteur

[@wassimyaich](https://github.com/wassimyaich)
