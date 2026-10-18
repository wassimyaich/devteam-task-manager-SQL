using Microsoft.EntityFrameworkCore;
using DevTeamTaskManager.Api.Data;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

builder.Services.AddControllers();

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddProblemDetails();
var app = builder.Build();

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler();
}
// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// app.UseHttpsRedirection();
if (!app.Environment.IsDevelopment())
{
    app.UseHttpsRedirection();
}
// app.UseAuthorization();
// app.UseDefaultFiles();
// app.UseStaticFiles();
app.UseDefaultFiles();
app.UseStaticFiles();
app.UseAuthorization();
app.MapControllers();

if (app.Environment.IsDevelopment())
{
    using var scope = app.Services.CreateScope();
    scope.ServiceProvider.GetRequiredService<AppDbContext>().Database.Migrate();
}
app.Run();