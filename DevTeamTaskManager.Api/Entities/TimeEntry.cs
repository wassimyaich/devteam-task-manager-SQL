using System;
using System.ComponentModel.DataAnnotations;

namespace DevTeamTaskManager.Api.Entities
{
    public class TimeEntry
    {
        public int Id { get; set; }

        [Required(ErrorMessage = "L'ID de la tâche est obligatoire.")]
        [Range(1, int.MaxValue, ErrorMessage = "L'ID de la tâche doit être valide.")]
        public int TaskId { get; set; }
        public TaskItem? Task { get; set; }

        [Required(ErrorMessage = "L'ID du développeur est obligatoire.")]
        [Range(1, int.MaxValue, ErrorMessage = "L'ID du développeur doit être valide.")]
        public int DeveloperId { get; set; }
        public Developer? Developer { get; set; }

        [Required(ErrorMessage = "La date de travail est obligatoire.")]
        [DataType(DataType.Date)]
        public DateTime WorkDate { get; set; } = DateTime.UtcNow;

        [Required(ErrorMessage = "La durée en heures est obligatoire.")]
        [Range(0.1, 24.0, ErrorMessage = "La durée imputée doit être comprise entre 0.1 et 24 heures par jour.")]
        public decimal DurationHours { get; set; }

        [StringLength(500, ErrorMessage = "La note ne peut pas dépasser 500 caractères.")]
        public string? Note { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}