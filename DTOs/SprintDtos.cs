using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using DevTeamTaskManager.Api.Enums;

namespace DevTeamTaskManager.Api.DTOs
{
    public class CreateSprintDto
    {
        [Required(ErrorMessage = "Le nom du sprint est obligatoire.")]
        [StringLength(100, MinimumLength = 1, ErrorMessage = "Le nom du sprint doit contenir entre 1 et 100 caractères.")]
        public string Name { get; set; } = string.Empty;
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        // public SprintStatus Status { get; set; }
        public List<int> TaskIds { get; set; } = new();
    }

    public class DeveloperAllocationDto
    {
        public int DeveloperId { get; set; }
        public string DeveloperName { get; set; } = string.Empty;
        public int AssignedTasksCount { get; set; }
        public decimal EstimatedHours { get; set; }
        public decimal LoggedHours { get; set; }
        public decimal CapacityHours { get; set; }
        public decimal AllocationPercentage { get; set; }
        public bool IsOverloaded { get; set; }
    }

    public class SprintCapacityReportDto
    {
        public int SprintId { get; set; }
        public string SprintName { get; set; } = string.Empty;
        public SprintStatus Status { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public int WorkingDays { get; set; }
        public int TotalTasks { get; set; }
        public int OpenTasks { get; set; }
        public decimal TotalEstimatedHours { get; set; }
        public decimal TotalLoggedHours { get; set; }
        public bool IsOverBudget { get; set; }
        public List<DeveloperAllocationDto> DeveloperAllocations { get; set; } = new();
    }
}