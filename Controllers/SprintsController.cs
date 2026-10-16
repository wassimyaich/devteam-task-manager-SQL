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
    public class SprintsController : ControllerBase
    {
        private readonly AppDbContext _context;

        public SprintsController(AppDbContext context)
        {
            _context = context;
        }
        private const decimal HoursPerWorkingDay = 7.0m;

        [HttpGet]
        public async Task<ActionResult<IEnumerable<object>>> GetSprints(CancellationToken ct)
        {
            var sprints = await _context.Sprints
                .AsNoTracking()
                .Select(s => new
                {
                    s.Id,
                    s.Name,
                    s.StartDate,
                    s.EndDate,
                    s.Status,
                    TaskCount = s.Tasks.Count
                })
                .ToListAsync(ct);

            return Ok(sprints);
        }

        [HttpGet("{id:int}/capacity")]
        public async Task<ActionResult<SprintCapacityReportDto>> GetSprintCapacity(int id, CancellationToken ct)
        {
            var report = await BuildCapacityReportAsync(id, ct);
            return report is null ? NotFound() : Ok(report);
        }

        [HttpPatch("{id:int}/close")]
        public async Task<IActionResult> CloseSprint(int id, CancellationToken ct)
        {
            var sprint = await _context.Sprints
                .Include(s => s.Tasks)
                .FirstOrDefaultAsync(s => s.Id == id, ct);

            if (sprint == null) return NotFound();

            if (sprint.Status == SprintStatus.Closed)
                return Conflict(new { message = "Ce sprint est déjà clôturé." });

            sprint.Status = SprintStatus.Closed;

            // Les tâches non terminées retournent au backlog
            foreach (var task in sprint.Tasks.Where(t => t.Status != Status.Completed).ToList())
            {
                task.SprintId = null;
            }

            await _context.SaveChangesAsync(ct);
            return NoContent();
        }

        [HttpGet("active")]
        public async Task<ActionResult<IEnumerable<object>>> GetActiveSprints(CancellationToken ct)
        {
            var sprints = await _context.Sprints
                .AsNoTracking()
                .Where(s => s.Status != SprintStatus.Closed)
                .OrderByDescending(s => s.StartDate)
                .Take(10)
                .Select(s => new { s.Id, s.Name, s.StartDate, s.EndDate, s.Status })
                .ToListAsync(ct);

            return Ok(sprints);
        }

        [HttpPost]
        public async Task<ActionResult<SprintCapacityReportDto>> CreateSprint([FromBody] CreateSprintDto dto, CancellationToken ct)
        {
            if (dto.StartDate == default || dto.EndDate == default)
                return BadRequest(new { message = "Les dates de début et de fin sont obligatoires." });

            if (dto.EndDate.Date < dto.StartDate.Date)
                return BadRequest(new { message = "La date de fin du sprint doit être postérieure ou égale à la date de début." });

            var taskIds = dto.TaskIds?.Distinct().ToList() ?? new List<int>();

            var tasksToAttach = taskIds.Count == 0
                ? new List<TaskItem>()
                : await _context.Tasks.Where(t => taskIds.Contains(t.Id)).ToListAsync(ct);

            if (tasksToAttach.Count != taskIds.Count)
                return BadRequest(new { message = "Une ou plusieurs tâches sélectionnées sont introuvables." });

            var sprint = new Sprint
            {
                Name = dto.Name.Trim(),
                StartDate = DateTime.SpecifyKind(dto.StartDate.Date, DateTimeKind.Utc),
                EndDate = DateTime.SpecifyKind(dto.EndDate.Date, DateTimeKind.Utc),
                Status = SprintStatus.Active
            };

            foreach (var task in tasksToAttach)
            {
                sprint.Tasks.Add(task);
            }

            // Un seul SaveChanges = une seule transaction (sprint + affectation des tâches)
            _context.Sprints.Add(sprint);
            await _context.SaveChangesAsync(ct);

            // Le taux d'affectation par développeur est renvoyé dès la création
            var report = await BuildCapacityReportAsync(sprint.Id, ct);

            return CreatedAtAction(nameof(GetSprintCapacity), new { id = sprint.Id }, report);
        }

        private async Task<SprintCapacityReportDto?> BuildCapacityReportAsync(int id, CancellationToken ct)
        {
            var sprint = await _context.Sprints
                .AsNoTracking()
                .Include(s => s.Tasks)
                    .ThenInclude(t => t.TimeEntries)
                .FirstOrDefaultAsync(s => s.Id == id, ct);

            if (sprint is null) return null;

            var workingDays = CountWorkingDays(sprint.StartDate, sprint.EndDate);
            var capacityPerDeveloper = workingDays * HoursPerWorkingDay;

            // Tous les développeurs apparaissent, même ceux sans tâche dans le sprint (0 %)
            var developers = await _context.Developers
                .AsNoTracking()
                .OrderBy(d => d.Name)
                .ToListAsync(ct);

            var sprintEntries = sprint.Tasks.SelectMany(t => t.TimeEntries).ToList();

            var allocations = developers.Select(dev =>
            {
                var devTasks = sprint.Tasks.Where(t => t.AssigneeId == dev.Id).ToList();
                var estimated = devTasks.Sum(t => t.EstimatedHours);

                return new DeveloperAllocationDto
                {
                    DeveloperId = dev.Id,
                    DeveloperName = dev.Name,
                    AssignedTasksCount = devTasks.Count,
                    EstimatedHours = estimated,
                    // Temps réellement saisi par CE développeur dans ce sprint
                    LoggedHours = sprintEntries.Where(te => te.DeveloperId == dev.Id).Sum(te => te.DurationHours),
                    CapacityHours = capacityPerDeveloper,
                    AllocationPercentage = capacityPerDeveloper > 0
                        ? Math.Round(estimated / capacityPerDeveloper * 100, 2)
                        : 0,
                    IsOverloaded = estimated > capacityPerDeveloper
                };
            }).ToList();

            var totalEstimated = sprint.Tasks.Sum(t => t.EstimatedHours);
            var totalLogged = sprintEntries.Sum(te => te.DurationHours);

            return new SprintCapacityReportDto
            {
                SprintId = sprint.Id,
                SprintName = sprint.Name,
                Status = sprint.Status,
                StartDate = sprint.StartDate,
                EndDate = sprint.EndDate,
                WorkingDays = workingDays,
                TotalTasks = sprint.Tasks.Count,
                OpenTasks = sprint.Tasks.Count(t => t.Status != Status.Completed),
                TotalEstimatedHours = totalEstimated,
                TotalLoggedHours = totalLogged,
                IsOverBudget = totalLogged > totalEstimated,
                DeveloperAllocations = allocations
            };
        }

        private static int CountWorkingDays(DateTime start, DateTime end)
        {
            var days = 0;
            for (var d = start.Date; d <= end.Date; d = d.AddDays(1))
            {
                if (d.DayOfWeek != DayOfWeek.Saturday && d.DayOfWeek != DayOfWeek.Sunday)
                    days++;
            }
            return Math.Max(days, 1);
        }
    }
}