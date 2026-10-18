using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using DevTeamTaskManager.Api.Enums;

namespace DevTeamTaskManager.Api.Entities
{
    public class Sprint
    {
        public int Id { get; set; }

        [Required(ErrorMessage = "Le nom du sprint est obligatoire.")]
        [StringLength(100, ErrorMessage = "Le nom du sprint ne peut pas dépasser 100 caractères.")]
        public string Name { get; set; } = string.Empty;

        [Required(ErrorMessage = "La date de début est obligatoire.")]
        [DataType(DataType.Date)]
        public DateTime StartDate { get; set; }

        [Required(ErrorMessage = "La date de fin est obligatoire.")]
        [DataType(DataType.Date)]
        public DateTime EndDate { get; set; }

        [Required(ErrorMessage = "Le statut du sprint est obligatoire.")]
        [EnumDataType(typeof(SprintStatus), ErrorMessage = "Le statut du sprint spécifié est invalide.")]
        public SprintStatus Status { get; set; } = SprintStatus.Planned;

        // Navigation property
        public ICollection<TaskItem> Tasks { get; set; } = new List<TaskItem>();
    }
}