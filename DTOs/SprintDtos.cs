using System;
using System.Collections.Generic;
using DevTeamTaskManager.Api.Enums;

namespace DevTeamTaskManager.Api.DTOs
{
    public class CreateSprintDto
    {
        public string Name { get; set; } = string.Empty;
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public SprintStatus Status { get; set; }
        public List<int> TaskIds { get; set; } = new();
    }

    public class SprintCapacityDto
    {
        public int SprintId { get; set; }
        public string SprintName { get; set; } = string.Empty;
        public SprintStatus Status { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public int TotalTasks { get; set; }
        public decimal TotalEstimatedHours { get; set; }
        public decimal TotalLoggedHours { get; set; }
    }
}