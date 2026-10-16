using System;

namespace DevTeamTaskManager.Api.DTOs
{
    public class CreateTimeEntryDto
    {
        public int TaskId { get; set; }
        public int DeveloperId { get; set; }
        public DateTime WorkDate { get; set; }
        public decimal DurationHours { get; set; }
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