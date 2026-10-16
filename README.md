# DevTeam Task Manager

Application de gestion de tâches et de suivi de sprints conçue pour les équipes de développement. Elle permet de piloter les flux de travail via un tableau Kanban interactif, de suivre la charge des développeurs et de gérer les capacités des sprints.

## 🚀 Stack Technique

- **Backend** : .NET 10, ASP.NET Core Web API, Entity Framework Core, SQL Server.
- **Frontend** : HTML5, Bootstrap 5, jQuery, FontAwesome 6, JavaScript (ES6+).
- **Architecture** : Pattern API RESTful, validation par DTOs, gestion des transactions et des codes d'erreur normalisés.

---

## ⚙️ Prérequis et Installation

Assurez-vous d'avoir installé sur votre poste :

- [.NET 10 SDK](https://dotnet.microsoft.com/)
- [SQL Server](https://www.microsoft.com/sql-server) (ou SQL Server Express / LocalDB)

### 1. Cloner le projet et configurer la base de données

Ouvrez le fichier `appsettings.json` dans le projet API pour configurer votre chaîne de connexion SQL Server (`ConnectionStrings:DefaultConnection`).

### 2. Appliquer les migrations EF Core

Ouvrez un terminal à la racine du projet et exécutez les commandes suivantes :

```bash
# Restaurer les dépendances
dotnet restore

# Appliquer les migrations pour créer la base de données et les tables
dotnet ef database update --project DevTeamTaskManager.Api
```
