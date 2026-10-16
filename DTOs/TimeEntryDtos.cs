using System;
using System.ComponentModel.DataAnnotations;
namespace DevTeamTaskManager.Api.DTOs
{
    public class CreateTimeEntryDto
    {
        [Range(1, int.MaxValue, ErrorMessage = "La tâche est invalide.")]
        public int TaskId { get; set; }

        [Range(1, int.MaxValue, ErrorMessage = "Le développeur est invalide.")]
        public int DeveloperId { get; set; }

        public DateTime WorkDate { get; set; }

        [Range(0.1, 24.0, ErrorMessage = "La durée doit être comprise entre 0.1 et 24 heures.")]
        public decimal DurationHours { get; set; }

        [StringLength(500, ErrorMessage = "La note ne peut pas dépasser 500 caractères.")]
        public string? Note { get; set; }
    }

    public class TimeEntryResponseDto
    {
        public int Id { get; set; }
        public int TaskId { get; set; }
        public string Client { get; set; } = string.Empty;
        public int DeveloperId { get; set; }
        public string DeveloperName { get; set; } = string.Empty;
        public DateTime WorkDate { get; set; }
        public decimal DurationHours { get; set; }
        public string? Note { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}