using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace DevTeamTaskManager.Api.Entities
{
    public class Developer
    {
        public int Id { get; set; }

        [Required(ErrorMessage = "Le nom du développeur est obligatoire.")]
        [StringLength(100, ErrorMessage = "Le nom ne peut pas dépasser 100 caractères.")]
        public string Name { get; set; } = string.Empty;

        [EmailAddress(ErrorMessage = "Le format de l'adresse email est invalide.")]
        [StringLength(150, ErrorMessage = "L'email ne peut pas dépasser 150 caractères.")]
        public string? Email { get; set; }

        // Navigation properties
        public ICollection<TaskItem> Tasks { get; set; } = new List<TaskItem>();
        public ICollection<TimeEntry> TimeEntries { get; set; } = new List<TimeEntry>();
    }
}