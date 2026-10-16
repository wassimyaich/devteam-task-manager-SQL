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

        public TasksController(AppDbContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<ActionResult<object>> GetTasks(
     [FromQuery] string? client,
     [FromQuery] int? assigneeId,
     [FromQuery] Status? status,
     [FromQuery] Priority? priority,
     [FromQuery] int? sprintId,
     [FromQuery] bool? unassigned,
     [FromQuery] int pageNumber = 1,
     [FromQuery] int pageSize = 15)
        {
            var query = _context.Tasks
                .Include(t => t.Assignee)
                .Include(t => t.Sprint)
                .Include(t => t.TimeEntries)
                .AsQueryable();

            // Application des filtres existants
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

            // 1. Comptage du total des enregistrements avant le découpage
            var totalRecords = await query.CountAsync();

            // 2. Application du tri, du Skip et du Take pour la pagination
            var tasks = await query
                .OrderByDescending(t => t.CreatedAt)
                .Skip((pageNumber - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            var totalPages = (int)Math.Ceiling(totalRecords / (double)pageSize);

            // 3. Retour d'un objet structuré avec métadonnées
            return Ok(new
            {
                Items = tasks.Select(MapToDto),
                PageNumber = pageNumber,
                PageSize = pageSize,
                TotalPages = totalPages,
                TotalRecords = totalRecords
            });
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<TaskResponseDto>> GetTask(int id)
        {
            var t = await _context.Tasks
                .Include(t => t.Assignee)
                .Include(t => t.Sprint)
                .Include(t => t.TimeEntries)
                .FirstOrDefaultAsync(x => x.Id == id);

            if (t == null) return NotFound();

            return Ok(MapToDto(t));
        }

        [HttpGet("{id}/report")]
        public async Task<ActionResult<TaskReportDto>> GetTaskReport(int id)
        {
            var task = await _context.Tasks
                .Include(t => t.TimeEntries)
                    .ThenInclude(te => te.Developer)
                .FirstOrDefaultAsync(t => t.Id == id);

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
                var sprintExists = await _context.Sprints.AnyAsync(s => s.Id == dto.SprintId.Value);
                if (!sprintExists)
                {
                    return BadRequest(new { message = "Le sprint cible est introuvable." });
                }
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
                task.DueDate = dto.DueDate.Value;

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

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteTask(int id)
        {
            // Inclure les TimeEntries pour pouvoir les supprimer proprement si nécessaire
            var task = await _context.Tasks
                .Include(t => t.TimeEntries)
                .FirstOrDefaultAsync(t => t.Id == id);

            if (task == null) return NotFound();

            try
            {
                // Supprimer d'abord les imputations de temps liées pour éviter les conflits de clés étrangères
                if (task.TimeEntries != null && task.TimeEntries.Any())
                {
                    _context.TimeEntries.RemoveRange(task.TimeEntries);
                }

                _context.Tasks.Remove(task);
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateException ex)
            {
                return BadRequest(new { message = "Impossible de supprimer cette tâche en raison de contraintes de données liées.", details = ex.InnerException?.Message ?? ex.Message });
            }

            return NoContent();
        }
        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateTask(int id, UpdateTaskDto dto)
        {
            // 1. Validation de l'existence des clés étrangères AVANT la modification
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
                var sprintExists = await _context.Sprints.AnyAsync(s => s.Id == dto.SprintId.Value);
                if (!sprintExists)
                {
                    return BadRequest(new { message = "Le sprint cible est introuvable." });
                }
            }

            // 2. Recherche et mise à jour de la tâche
            var task = await _context.Tasks.FindAsync(id);
            if (task == null) return NotFound();

            task.Client = dto.Client;
            task.Description = dto.Description;
            task.AssigneeId = dto.AssigneeId;
            task.EstimatedHours = dto.EstimatedHours;
            task.DueDate = dto.DueDate;
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