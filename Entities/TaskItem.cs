using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using DevTeamTaskManager.Api.Enums;

namespace DevTeamTaskManager.Api.Entities
{
    public class TaskItem
    {
        public int Id { get; set; }

        [Required(ErrorMessage = "Le champ Client est obligatoire.")]
        [StringLength(100, ErrorMessage = "Le nom du client ne peut pas dépasser 100 caractères.")]
        public string Client { get; set; } = string.Empty;

        [Required(ErrorMessage = "La description est obligatoire.")]
        public string Description { get; set; } = string.Empty;

        // Foreign Key for Developer
        [Required(ErrorMessage = "L'assignation d'un développeur est obligatoire.")]
        [Range(1, int.MaxValue, ErrorMessage = "L'ID du développeur assigné doit être valide.")]
        public int AssigneeId { get; set; }
        public Developer? Assignee { get; set; }

        [Required(ErrorMessage = "L'estimation est obligatoire.")]
        [Range(0.1, 1000.0, ErrorMessage = "L'estimation en heures doit être comprise entre 0.1 et 1000.")]
        public decimal EstimatedHours { get; set; } // Stored consistently in hours

        [Required(ErrorMessage = "La date d'échéance est obligatoire.")]
        [DataType(DataType.Date)]
        public DateTime DueDate { get; set; }

        [Required(ErrorMessage = "La priorité est obligatoire.")]
        [EnumDataType(typeof(Priority), ErrorMessage = "La priorité spécifiée est invalide.")]
        public Priority Priority { get; set; }

        [Required(ErrorMessage = "Le statut est obligatoire.")]
        [EnumDataType(typeof(Status), ErrorMessage = "Le statut spécifié est invalide.")]
        public Status Status { get; set; }

        // Optional Foreign Key for Sprint
        public int? SprintId { get; set; }
        public Sprint? Sprint { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }

        // Navigation property
        public ICollection<TimeEntry> TimeEntries { get; set; } = new List<TimeEntry>();
    }
}