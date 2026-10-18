using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using DevTeamTaskManager.Api.Data;
using DevTeamTaskManager.Api.Entities;
using DevTeamTaskManager.Api.DTOs;

namespace DevTeamTaskManager.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class TimeEntriesController : ControllerBase
    {
        private readonly AppDbContext _context;

        public TimeEntriesController(AppDbContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<TimeEntryResponseDto>>> GetTimeEntries(CancellationToken ct)
        {
            var entries = await _context.TimeEntries
                .AsNoTracking()
                .Select(te => new TimeEntryResponseDto
                {
                    Id = te.Id,
                    TaskId = te.TaskId,
                    Client = te.Task != null ? te.Task.Client : string.Empty,
                    DeveloperId = te.DeveloperId,
                    DeveloperName = te.Developer != null ? te.Developer.Name : string.Empty,
                    WorkDate = te.WorkDate,
                    DurationHours = te.DurationHours,
                    Note = te.Note,
                    CreatedAt = te.CreatedAt
                })
                .ToListAsync(ct);

            return Ok(entries);
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<TimeEntryResponseDto>> GetTimeEntry(int id)
        {
            var entry = await _context.TimeEntries
                .Include(te => te.Task)
                .Include(te => te.Developer)
                .FirstOrDefaultAsync(te => te.Id == id);

            if (entry == null) return NotFound();

            var response = new TimeEntryResponseDto
            {
                Id = entry.Id,
                TaskId = entry.TaskId,
                Client = entry.Task?.Client ?? string.Empty,
                DeveloperId = entry.DeveloperId,
                DeveloperName = entry.Developer?.Name ?? string.Empty,
                WorkDate = entry.WorkDate,
                DurationHours = entry.DurationHours,
                Note = entry.Note,
                CreatedAt = entry.CreatedAt
            };

            return Ok(response);
        }

        [HttpPost]
        public async Task<ActionResult<TimeEntryResponseDto>> CreateTimeEntry(CreateTimeEntryDto dto)
        {
            // if (!ModelState.IsValid)
            // {
            //     return BadRequest(ModelState);
            // }

            // if (dto.DurationHours <= 0 || dto.DurationHours > 24)
            // {
            //     return BadRequest(new { message = "La durée en heures doit être comprise entre 0.1 et 24 heures pour une seule entrée." });
            // }

            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            if (dto.DurationHours < 0.1m || dto.DurationHours > 24m)
            {
                return BadRequest(new
                {
                    message = "La durée doit être comprise entre 0.1 et 24 heures."
                });
            }

            var task = await _context.Tasks.AsNoTracking().FirstOrDefaultAsync(t => t.Id == dto.TaskId);
            var developer = await _context.Developers.AsNoTracking().FirstOrDefaultAsync(d => d.Id == dto.DeveloperId);

            if (task == null || developer == null)
            {
                return BadRequest(new { message = "TaskId ou DeveloperId invalide." });
            }

            var workDay = (dto.WorkDate == default ? DateTime.UtcNow : dto.WorkDate).Date;

            // +1 jour de tolérance pour le décalage horaire (Tunisie = UTC+1)
            if (workDay > DateTime.UtcNow.Date.AddDays(1))
            {
                return BadRequest(new { message = "La date de travail ne peut pas être dans le futur." });
            }

            var alreadyLogged = await _context.TimeEntries
                .Where(te => te.DeveloperId == dto.DeveloperId
                          && te.WorkDate >= workDay
                          && te.WorkDate < workDay.AddDays(1))
                .SumAsync(te => te.DurationHours);

            if (alreadyLogged + dto.DurationHours > 24m)
            {
                return BadRequest(new
                {
                    message = $"Total journalier dépassé : {alreadyLogged} h déjà imputées ce jour-là (maximum 24 h)."
                });
            }

            var timeEntry = new TimeEntry
            {
                TaskId = dto.TaskId,
                DeveloperId = dto.DeveloperId,
                // WorkDate = dto.WorkDate == default ? DateTime.UtcNow : dto.WorkDate,
                WorkDate = dto.WorkDate == default
                    ? DateTime.UtcNow
                    : DateTime.SpecifyKind(dto.WorkDate, DateTimeKind.Utc),
                DurationHours = dto.DurationHours,
                Note = dto.Note,
                CreatedAt = DateTime.UtcNow
            };

            _context.TimeEntries.Add(timeEntry);
            await _context.SaveChangesAsync();

            var response = new TimeEntryResponseDto
            {
                Id = timeEntry.Id,
                TaskId = timeEntry.TaskId,
                Client = task.Client,
                DeveloperId = timeEntry.DeveloperId,
                DeveloperName = developer.Name,
                WorkDate = timeEntry.WorkDate,
                DurationHours = timeEntry.DurationHours,
                Note = timeEntry.Note,
                CreatedAt = timeEntry.CreatedAt
            };

            return CreatedAtAction(nameof(GetTimeEntry), new { id = timeEntry.Id }, response);
        }
        [HttpDelete("{id:int}")]
        public async Task<IActionResult> DeleteTimeEntry(
    int id,
    CancellationToken ct)
        {
            if (id <= 0)
            {
                return BadRequest(new
                {
                    message = "L'identifiant de l'imputation est invalide."
                });
            }

            var entry = await _context.TimeEntries
                .FirstOrDefaultAsync(te => te.Id == id, ct);

            if (entry == null)
            {
                return NotFound();
            }

            _context.TimeEntries.Remove(entry);
            await _context.SaveChangesAsync(ct);

            return NoContent();
        }

    }
}