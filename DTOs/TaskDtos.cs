using System;
using System.ComponentModel.DataAnnotations;
using DevTeamTaskManager.Api.Enums;

namespace DevTeamTaskManager.Api.DTOs
{
    public class CreateTaskDto
    {
        [Required]
        [StringLength(100, MinimumLength = 1)]
        public string Client { get; set; } = string.Empty;

        [Required]
        [StringLength(2000, MinimumLength = 1)]
        public string Description { get; set; } = string.Empty;

        [Range(1, int.MaxValue)]
        public int AssigneeId { get; set; }

        // [Range(typeof(decimal), "0.1", "1000")]
        [Range(0.1, 1000.0, ErrorMessage = "L'estimation doit être comprise entre 0.1 et 1000 heures.")]
        public decimal EstimatedHours { get; set; }

        [Required]
        public DateTime DueDate { get; set; }

        [EnumDataType(typeof(Priority))]
        public Priority Priority { get; set; }

        [Range(1, int.MaxValue)]
        public int? SprintId { get; set; }
    }

    public class UpdateTaskDto : CreateTaskDto
    {
        [EnumDataType(typeof(Status))]
        public Status? Status { get; set; }
    }

    public class InlineUpdateTaskDto
    {
        // [Range(typeof(decimal), "0.1", "1000")]
        [Range(0.1, 1000.0, ErrorMessage = "L'estimation doit être comprise entre 0.1 et 1000 heures.")]
        public decimal? EstimatedHours { get; set; }

        public DateTime? DueDate { get; set; }
    }

    public class UpdateTaskStatusDto
    {
        [EnumDataType(typeof(Status))]
        public Status Status { get; set; }
    }

    public class TaskResponseDto
    {
        public int Id { get; set; }
        public string Client { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public int AssigneeId { get; set; }
        public string AssigneeName { get; set; } = string.Empty;
        public decimal EstimatedHours { get; set; }
        public DateTime DueDate { get; set; }
        public Priority Priority { get; set; }
        public Status Status { get; set; }
        public int? SprintId { get; set; }
        public string? SprintName { get; set; }
        public decimal LoggedHours { get; set; }
        public bool IsOverBudget { get; set; }
        public DateTime CreatedAt { get; set; }
    }

    public class TaskReportDto
    {
        public int TaskId { get; set; }
        public string Client { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public decimal EstimatedHours { get; set; }
        public decimal LoggedHours { get; set; }
        public bool IsOverBudget { get; set; }
        public IEnumerable<TimeEntryResponseDto> TimeEntries { get; set; } = [];
    }


    public class PagedResult<T>
    {
        public IEnumerable<T> Items { get; set; } = [];
        public int PageNumber { get; set; }
        public int PageSize { get; set; }
        public int TotalPages { get; set; }
        public int TotalRecords { get; set; }
    }

}
