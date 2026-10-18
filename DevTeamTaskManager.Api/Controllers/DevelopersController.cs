using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using DevTeamTaskManager.Api.Data;
using DevTeamTaskManager.Api.Entities;

namespace DevTeamTaskManager.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class DevelopersController : ControllerBase
    {
        private readonly AppDbContext _context;

        public DevelopersController(AppDbContext context)
        {
            _context = context;

        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<Developer>>> GetDevelopers(CancellationToken ct)
        {
            return await _context.Developers.AsNoTracking().OrderBy(d => d.Name).ToListAsync(ct);
        }

        [HttpGet("search")]
        public async Task<ActionResult<IEnumerable<Developer>>> SearchDevelopers([FromQuery] string term, CancellationToken ct)
        {
            if (string.IsNullOrWhiteSpace(term) || term.Length < 2)
            {
                return Ok(new List<Developer>());
            }

            var developers = await _context.Developers
                .AsNoTracking()
                .Where(d => d.Name.Contains(term) || (d.Email != null && d.Email.Contains(term)))
                .Take(10)
                .ToListAsync(ct);

            return Ok(developers);
        }
    }
}