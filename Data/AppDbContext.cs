using Microsoft.EntityFrameworkCore;
using DevTeamTaskManager.Api.Entities;
using DevTeamTaskManager.Api.Enums;
using System;

namespace DevTeamTaskManager.Api.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

        public DbSet<Developer> Developers => Set<Developer>();
        public DbSet<Sprint> Sprints => Set<Sprint>();
        public DbSet<TaskItem> Tasks => Set<TaskItem>();
        public DbSet<TimeEntry> TimeEntries => Set<TimeEntry>();

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Configure Decimal Precisions
            modelBuilder.Entity<TaskItem>()
                .Property(t => t.EstimatedHours)
                .HasColumnType("decimal(18,2)");

            modelBuilder.Entity<TimeEntry>()
                .Property(te => te.DurationHours)
                .HasColumnType("decimal(18,2)");

            // Configure Delete Behaviors
            modelBuilder.Entity<TaskItem>()
                .HasMany(t => t.TimeEntries)
                .WithOne(te => te.Task)
                .HasForeignKey(te => te.TaskId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Developer>()
                .HasMany(d => d.TimeEntries)
                .WithOne(te => te.Developer)
                .HasForeignKey(te => te.DeveloperId)
                .OnDelete(DeleteBehavior.Restrict);
            modelBuilder.Entity<TaskItem>()
                            .HasOne(t => t.Assignee)
                            .WithMany(d => d.Tasks)
                            .HasForeignKey(t => t.AssigneeId)
                            .OnDelete(DeleteBehavior.Restrict);

            // Index sur les colonnes filtrées
            modelBuilder.Entity<TaskItem>().HasIndex(t => t.Status);
            modelBuilder.Entity<TaskItem>().HasIndex(t => t.Priority);
            modelBuilder.Entity<TaskItem>().HasIndex(t => t.Client);
            // Seed Initial Development Data
            modelBuilder.Entity<Developer>().HasData(
                new Developer { Id = 1, Name = "Wassim Yaich", Email = "wassim@devteam.local" },
                new Developer { Id = 2, Name = "Sarah Ben Ali", Email = "sarah@devteam.local" },
                new Developer { Id = 3, Name = "Mehdi Trabelsi", Email = "mehdi@devteam.local" }
            );

            modelBuilder.Entity<Sprint>().HasData(
                new Sprint
                {
                    Id = 1,
                    Name = "Sprint 1 - MVP Foundation",
                    StartDate = new DateTime(2026, 10, 12),
                    EndDate = new DateTime(2026, 10, 30),
                    Status = SprintStatus.Active
                }
            );
        }
    }
}