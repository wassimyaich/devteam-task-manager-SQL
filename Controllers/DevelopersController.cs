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
        public async Task<ActionResult<IEnumerable<Developer>>> GetDevelopers()
        {
            return await _context.Developers.ToListAsync();
        }

        [HttpGet("search")]
        public async Task<ActionResult<IEnumerable<Developer>>> SearchDevelopers([FromQuery] string term)
        {
            if (string.IsNullOrWhiteSpace(term) || term.Length < 2)
            {
                return Ok(new List<Developer>());
            }

            var developers = await _context.Developers
                .Where(d => d.Name.Contains(term) || (d.Email != null && d.Email.Contains(term)))
                .Take(10)
                .ToListAsync();

            return Ok(developers);
        }
    }
}