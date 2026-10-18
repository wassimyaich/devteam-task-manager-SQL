using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using DevTeamTaskManager.Api.Data;
using DevTeamTaskManager.Api.Entities;
using DevTeamTaskManager.Api.DTOs;
using DevTeamTaskManager.Api.Enums;

namespace DevTeamTaskManager.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class TasksController : ControllerBase
    {
        private readonly AppDbContext _context;
        private const int MaxPageSize = 100;
        public TasksController(AppDbContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<ActionResult<PagedResult<TaskResponseDto>>> GetTasks(
            [FromQuery] string? client,
            [FromQuery] int? assigneeId,
            [FromQuery] Status? status,
            [FromQuery] Priority? priority,
            [FromQuery] int? sprintId,
            [FromQuery] bool? unassigned,
            [FromQuery] int pageNumber = 1,
            [FromQuery] int pageSize = 15,
            CancellationToken ct = default)
        {
            pageNumber = Math.Max(1, pageNumber);
            pageSize = Math.Clamp(pageSize, 1, MaxPageSize);

            var query = _context.Tasks.AsNoTracking().AsQueryable();

            if (!string.IsNullOrWhiteSpace(client))
                query = query.Where(t => t.Client.Contains(client));

            if (assigneeId.HasValue)
                query = query.Where(t => t.AssigneeId == assigneeId.Value);

            if (status.HasValue)
                query = query.Where(t => t.Status == status.Value);

            if (priority.HasValue)
                query = query.Where(t => t.Priority == priority.Value);

            if (sprintId.HasValue)
                query = query.Where(t => t.SprintId == sprintId.Value);

            if (unassigned == true)
                query = query.Where(t => t.SprintId == null);

            var totalRecords = await query.CountAsync(ct);

            // Projection SQL : on ne charge plus toutes les imputations de temps en mémoire
            var items = await query
                .OrderByDescending(t => t.CreatedAt)
                .ThenByDescending(t => t.Id)
                .Skip((pageNumber - 1) * pageSize)
                .Take(pageSize)
                .Select(t => new TaskResponseDto
                {
                    Id = t.Id,
                    Client = t.Client,
                    Description = t.Description,
                    AssigneeId = t.AssigneeId,
                    AssigneeName = t.Assignee != null ? t.Assignee.Name : "Unassigned",
                    EstimatedHours = t.EstimatedHours,
                    DueDate = t.DueDate,
                    Priority = t.Priority,
                    Status = t.Status,
                    SprintId = t.SprintId,
                    SprintName = t.Sprint != null ? t.Sprint.Name : null,
                    LoggedHours = t.TimeEntries.Sum(te => te.DurationHours),
                    IsOverBudget = t.TimeEntries.Sum(te => te.DurationHours) > t.EstimatedHours,
                    CreatedAt = t.CreatedAt
                })
                .ToListAsync(ct);

            return Ok(new PagedResult<TaskResponseDto>
            {
                Items = items,
                PageNumber = pageNumber,
                PageSize = pageSize,
                TotalPages = (int)Math.Ceiling(totalRecords / (double)pageSize),
                TotalRecords = totalRecords
            });
        }
        [HttpGet("{id}")]
        public async Task<ActionResult<TaskResponseDto>> GetTask(int id, CancellationToken ct)
        {
            var t = await _context.Tasks
                .AsNoTracking()
                .Include(t => t.Assignee)
                .Include(t => t.Sprint)
                .Include(t => t.TimeEntries)
                .FirstOrDefaultAsync(x => x.Id == id, ct);

            if (t == null) return NotFound();

            return Ok(MapToDto(t));
        }

        [HttpGet("{id}/report")]
        public async Task<ActionResult<TaskReportDto>> GetTaskReport(int id, CancellationToken ct)
        {
            var task = await _context.Tasks
                .AsNoTracking()
                .Include(t => t.TimeEntries)
                    .ThenInclude(te => te.Developer)
                .FirstOrDefaultAsync(t => t.Id == id, ct);

            if (task == null) return NotFound();

            var logged = task.TimeEntries.Sum(te => te.DurationHours);

            return Ok(new TaskReportDto
            {
                TaskId = task.Id,
                Client = task.Client,
                Description = task.Description,
                EstimatedHours = task.EstimatedHours,
                LoggedHours = logged,
                IsOverBudget = logged > task.EstimatedHours,
                TimeEntries = task.TimeEntries
                    .OrderByDescending(te => te.WorkDate)
                    .Select(te => new TimeEntryResponseDto
                    {
                        Id = te.Id,
                        TaskId = te.TaskId,
                        Client = task.Client,
                        DeveloperId = te.DeveloperId,
                        DeveloperName = te.Developer?.Name ?? string.Empty,
                        WorkDate = te.WorkDate,
                        DurationHours = te.DurationHours,
                        Note = te.Note,
                        CreatedAt = te.CreatedAt
                    })
            });
        }

        [HttpPost]
        public async Task<ActionResult<TaskResponseDto>> CreateTask(CreateTaskDto dto)
        {

            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            if (string.IsNullOrWhiteSpace(dto.Client)
                || string.IsNullOrWhiteSpace(dto.Description))
            {
                return BadRequest(new
                {
                    message = "Le client et la description sont obligatoires."
                });
            }

            if (dto.DueDate == default)
            {
                return BadRequest(new
                {
                    message = "La date d'échéance est obligatoire et doit être valide."
                });
            }

            if (!Enum.IsDefined(typeof(Priority), dto.Priority))
            {
                return BadRequest(new
                {
                    message = "La priorité sélectionnée est invalide."
                });
            }

            // 1. Validation de l'existence des clés étrangères AVANT la création
            if (dto.AssigneeId > 0)
            {
                var developerExists = await _context.Developers.AnyAsync(d => d.Id == dto.AssigneeId);
                if (!developerExists)
                {
                    return BadRequest(new { message = "Le développeur assigné est introuvable." });
                }
            }

            if (dto.SprintId.HasValue && dto.SprintId.Value > 0)
            {
                var sprint = await _context.Sprints
     .AsNoTracking()
     .FirstOrDefaultAsync(s => s.Id == dto.SprintId.Value);

                if (sprint == null)
                    return BadRequest(new { message = "Le sprint cible est introuvable." });

                if (sprint.Status == SprintStatus.Closed)
                    return BadRequest(new { message = "Impossible d'affecter une tâche à un sprint clôturé." });
            }

            // 2. Création de la tâche si tout est valide
            var taskItem = new TaskItem
            {
                Client = dto.Client,
                Description = dto.Description,
                AssigneeId = dto.AssigneeId,
                EstimatedHours = dto.EstimatedHours,
                // DueDate = dto.DueDate,
                DueDate = DateTime.SpecifyKind(dto.DueDate, DateTimeKind.Utc),
                Priority = dto.Priority,
                SprintId = dto.SprintId,
                Status = Status.ToDo,
                CreatedAt = DateTime.UtcNow
            };

            _context.Tasks.Add(taskItem);
            await _context.SaveChangesAsync();

            // 3. Chargement des relations pour que MapToDto retourne les bons noms (Assigné et Sprint)
            await _context.Entry(taskItem).Reference(t => t.Assignee).LoadAsync();
            await _context.Entry(taskItem).Reference(t => t.Sprint).LoadAsync();

            return CreatedAtAction(nameof(GetTask), new { id = taskItem.Id }, MapToDto(taskItem));
        }
        [HttpPatch("{id}/inline")]
        public async Task<IActionResult> InlineUpdateTask(int id, InlineUpdateTaskDto dto)
        {

            if (id <= 0)
                return BadRequest(new { message = "L'identifiant de la tâche est invalide." });

            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            if (!dto.EstimatedHours.HasValue && !dto.DueDate.HasValue)
            {
                return BadRequest(new
                {
                    message = "Fournissez au moins une valeur à modifier."
                });
            }

            if (dto.DueDate.HasValue && dto.DueDate.Value == default)
            {
                return BadRequest(new
                {
                    message = "La date d'échéance est invalide."
                });
            }

            if (dto.EstimatedHours.HasValue &&
     (dto.EstimatedHours.Value < 0.1m ||
      dto.EstimatedHours.Value > 1000m))
            {
                return BadRequest(new
                {
                    message =
                    "L'estimation doit être comprise entre 0.1 et 1000 heures."
                });
            }
            var task = await _context.Tasks.FindAsync(id);
            if (task == null) return NotFound();

            if (dto.EstimatedHours.HasValue)
                task.EstimatedHours = dto.EstimatedHours.Value;

            if (dto.DueDate.HasValue)
                task.DueDate = DateTime.SpecifyKind(dto.DueDate.Value, DateTimeKind.Utc);

            task.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return NoContent();
        }

        [HttpPatch("{id}/status")]
        public async Task<IActionResult> UpdateTaskStatus(int id, UpdateTaskStatusDto dto)
        {
            var task = await _context.Tasks.FindAsync(id);
            if (task == null) return NotFound();

            task.Status = dto.Status;
            task.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return NoContent();
        }

        [HttpDelete("{id:int}")]
        public async Task<IActionResult> DeleteTask(int id, CancellationToken ct)
        {
            var task = await _context.Tasks.FirstOrDefaultAsync(t => t.Id == id, ct);
            if (task == null) return NotFound();

            var hasTimeEntries = await _context.TimeEntries.AnyAsync(te => te.TaskId == id, ct);
            if (hasTimeEntries)
            {
                return Conflict(new { message = "Impossible de supprimer cette tâche : du temps a déjà été imputé dessus." });
            }

            _context.Tasks.Remove(task);
            await _context.SaveChangesAsync(ct);

            return NoContent();
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateTask(int id, UpdateTaskDto dto)
        {
            if (dto.DueDate == default)
                return BadRequest(new { message = "La date d'échéance est obligatoire et doit être valide." });
            // 1. Validation de l'existence des clés étrangères AVANT la modification
            if (dto.AssigneeId > 0)
            {
                var developerExists = await _context.Developers.AnyAsync(d => d.Id == dto.AssigneeId);
                if (!developerExists)
                {
                    return BadRequest(new { message = "Le développeur assigné est introuvable." });
                }
            }



            // 2. Recherche et mise à jour de la tâche
            var task = await _context.Tasks.FindAsync(id);
            if (task == null) return NotFound();

            if (dto.SprintId.HasValue && dto.SprintId != task.SprintId)
            {
                var targetSprint = await _context.Sprints
                    .AsNoTracking()
                    .FirstOrDefaultAsync(s => s.Id == dto.SprintId.Value);

                if (targetSprint == null)
                    return BadRequest(new { message = "Le sprint cible est introuvable." });

                if (targetSprint.Status == SprintStatus.Closed)
                    return BadRequest(new { message = "Impossible d'affecter une tâche à un sprint clôturé." });
            }
            task.Client = dto.Client;
            task.Description = dto.Description;
            task.AssigneeId = dto.AssigneeId;
            task.EstimatedHours = dto.EstimatedHours;
            // task.DueDate = dto.DueDate;
            task.DueDate = DateTime.SpecifyKind(dto.DueDate, DateTimeKind.Utc);
            task.Priority = dto.Priority;
            task.SprintId = dto.SprintId;

            if (dto.Status.HasValue)
            {
                task.Status = dto.Status.Value;
            }

            task.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return NoContent();
        }
        private static TaskResponseDto MapToDto(TaskItem t)
        {
            var logged = t.TimeEntries?.Sum(te => te.DurationHours) ?? 0;

            return new TaskResponseDto
            {
                Id = t.Id,
                Client = t.Client,
                Description = t.Description,
                AssigneeId = t.AssigneeId,
                AssigneeName = t.Assignee?.Name ?? "Unassigned",
                EstimatedHours = t.EstimatedHours,
                DueDate = t.DueDate,
                Priority = t.Priority,
                Status = t.Status,
                SprintId = t.SprintId,
                SprintName = t.Sprint?.Name,
                LoggedHours = logged,
                IsOverBudget = logged > t.EstimatedHours,
                CreatedAt = t.CreatedAt
            };
        }
    }
}