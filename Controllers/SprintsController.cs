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

        [HttpGet]
        public async Task<ActionResult<IEnumerable<object>>> GetSprints()
        {
            var sprints = await _context.Sprints
                .Include(s => s.Tasks)
                .Select(s => new
                {
                    s.Id,
                    s.Name,
                    s.StartDate,
                    s.EndDate,
                    s.Status,
                    TaskCount = s.Tasks.Count
                })
                .ToListAsync();

            return Ok(sprints);
        }



        [HttpGet("{id}/capacity")]
        public async Task<ActionResult<object>> GetSprintCapacity(int id)
        {
            var sprint = await _context.Sprints
                .Include(s => s.Tasks)
                .ThenInclude(t => t.Assignee)
                .Include(s => s.Tasks)
                .ThenInclude(t => t.TimeEntries)
                .FirstOrDefaultAsync(s => s.Id == id);

            if (sprint == null) return NotFound();

            var totalEstimated = sprint.Tasks.Sum(t => t.EstimatedHours);
            var totalLogged = sprint.Tasks.SelectMany(t => t.TimeEntries).Sum(te => te.DurationHours);

            // 1. Calculer le nombre de jours ouvrés du sprint (excluant les week-ends de façon simple)
            int totalDays = (int)(sprint.EndDate - sprint.StartDate).TotalDays + 1;
            int workingDays = 0;
            for (int i = 0; i < totalDays; i++)
            {
                var day = sprint.StartDate.AddDays(i);
                if (day.DayOfWeek != DayOfWeek.Saturday && day.DayOfWeek != DayOfWeek.Sunday)
                {
                    workingDays++;
                }
            }
            if (workingDays <= 0) workingDays = 1; // Sécurité anti division par zéro

            // 2. Capacité standard par développeur (ex: 7 heures par jour ouvré)
            const decimal hoursPerDay = 7.0m;
            decimal developerStandardCapacity = workingDays * hoursPerDay;

            // 3. Calculer l'affectation par rapport à la capacité réelle du développeur
            var developerAllocations = sprint.Tasks
                .GroupBy(t => new { t.AssigneeId, DeveloperName = t.Assignee != null ? t.Assignee.Name : "Unassigned" })
                .Select(g => new
                {
                    DeveloperId = g.Key.AssigneeId,
                    DeveloperName = g.Key.DeveloperName,
                    AssignedTasksCount = g.Count(),
                    EstimatedHours = g.Sum(t => t.EstimatedHours),
                    LoggedHours = g.SelectMany(t => t.TimeEntries).Sum(te => te.DurationHours),
                    CapacityHours = developerStandardCapacity,
                    // Vrai taux d'affectation : Heures estimées du dev / Capacité du dev
                    AllocationPercentage = developerStandardCapacity > 0
                        ? Math.Round((g.Sum(t => t.EstimatedHours) / developerStandardCapacity) * 100, 2)
                        : 0,
                    IsOverloaded = g.Sum(t => t.EstimatedHours) > developerStandardCapacity
                })
                .ToList();

            var report = new
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
                DeveloperAllocations = developerAllocations
            };

            return Ok(report);
        }


        [HttpPatch("{id}/close")]
        public async Task<IActionResult> CloseSprint(int id)
        {
            // Charger le sprint en incluant ses tâches associées
            var sprint = await _context.Sprints
                .Include(s => s.Tasks)
                .FirstOrDefaultAsync(s => s.Id == id);

            if (sprint == null) return NotFound();

            // 1. Clôturer le sprint
            sprint.Status = SprintStatus.Closed;

            // 2. Renvoyer toutes les tâches non terminées vers le Backlog (SprintId = null)
            foreach (var task in sprint.Tasks)
            {
                if (task.Status != Status.Completed)
                {
                    task.SprintId = null;
                }
            }

            await _context.SaveChangesAsync();

            return NoContent();
        }



        [HttpGet("active")]
        public async Task<ActionResult<IEnumerable<Sprint>>> GetActiveSprints()
        {
            // Par exemple, récupérer uniquement les sprints non clôturés ou récents
            return await _context.Sprints
                .Where(s => s.Status != SprintStatus.Closed) // ou selon votre logique de statut
                .OrderByDescending(s => s.StartDate)
                .Take(10) // Afficher les 10 sprints pertinents maximum
                .ToListAsync();
        }

        // [HttpPost]
        // public async Task<ActionResult<Sprint>> CreateSprint(CreateSprintDto dto)
        // {
        //     if (dto.EndDate < dto.StartDate)
        //     {
        //         return BadRequest("La date de fin du sprint doit être postérieure ou égale à la date de début.");
        //     }
        //     var sprint = new Sprint
        //     {
        //         Name = dto.Name,
        //         StartDate = dto.StartDate,
        //         EndDate = dto.EndDate,
        //         Status = dto.Status
        //     };

        //     _context.Sprints.Add(sprint);
        //     await _context.SaveChangesAsync();

        //     if (dto.TaskIds != null && dto.TaskIds.Count > 0)
        //     {
        //         var tasks = await _context.Tasks
        //             .Where(t => dto.TaskIds.Contains(t.Id))
        //             .ToListAsync();

        //         foreach (var task in tasks)
        //         {
        //             task.SprintId = sprint.Id;
        //         }

        //         await _context.SaveChangesAsync();
        //     }

        //     return CreatedAtAction(nameof(GetSprints), new { id = sprint.Id }, sprint);
        // }

        [HttpPost]
        public async Task<ActionResult<Sprint>> CreateSprint([FromBody] CreateSprintDto dto)
        {
            if (dto.EndDate < dto.StartDate)
            {
                return BadRequest(new { message = "La date de fin du sprint doit être postérieure ou égale à la date de début." });
            }
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                var sprint = new Sprint
                {
                    Name = dto.Name,
                    // StartDate = dto.StartDate,
                    // EndDate = dto.EndDate,
                    // CORRECTION ICI : Forcer le Kind en UTC
                    StartDate = DateTime.SpecifyKind(dto.StartDate, DateTimeKind.Utc),
                    EndDate = DateTime.SpecifyKind(dto.EndDate, DateTimeKind.Utc),
                    Status = SprintStatus.Active
                };

                _context.Sprints.Add(sprint);
                await _context.SaveChangesAsync();

                if (dto.TaskIds != null && dto.TaskIds.Any())
                {
                    var tasksToUpdate = await _context.Tasks
                        .Where(t => dto.TaskIds.Contains(t.Id))
                        .ToListAsync();

                    foreach (var task in tasksToUpdate)
                    {
                        task.SprintId = sprint.Id;
                    }
                    await _context.SaveChangesAsync();
                }

                await transaction.CommitAsync();

                // Retourner un DTO explicite pour éviter le cycle JSON
                var responseDto = new Sprint
                {
                    Id = sprint.Id,
                    Name = sprint.Name,
                    StartDate = sprint.StartDate,
                    EndDate = sprint.EndDate,
                    Status = sprint.Status
                };

                return CreatedAtAction(nameof(GetSprints), new { id = sprint.Id }, responseDto);
            }
            catch
            {
                await transaction.RollbackAsync();
                throw;
            }
        }
    }
}