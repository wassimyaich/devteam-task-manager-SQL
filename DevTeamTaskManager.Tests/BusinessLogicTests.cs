using DevTeamTaskManager.Api.Controllers;

namespace DevTeamTaskManager.Tests
{
    public class WorkingDaysTests
    {
        [Fact]
        public void WeekendOnly_ReturnsZero()
        {
            // Samedi 17 - dimanche 18 octobre 2026
            var days = SprintsController.CountWorkingDays(new DateTime(2026, 10, 17), new DateTime(2026, 10, 18));
            Assert.Equal(0, days);
        }

        [Fact]
        public void SingleWeekday_ReturnsOne()
        {
            // Lundi 12 octobre 2026
            var days = SprintsController.CountWorkingDays(new DateTime(2026, 10, 12), new DateTime(2026, 10, 12));
            Assert.Equal(1, days);
        }

        [Fact]
        public void FullWeek_ExcludesWeekendAndEvacuationDay()
        {
            // Lun 12 -> dim 18 octobre 2026 : 5 jours de semaine moins le jeudi 15 (fête de l'Évacuation)
            var days = SprintsController.CountWorkingDays(new DateTime(2026, 10, 12), new DateTime(2026, 10, 18));
            Assert.Equal(4, days);
        }

        [Fact]
        public void SprintAcrossNewYear_ExcludesNewYearsDayOfSecondYear()
        {
            // Lun 28 déc 2026 -> lun 4 jan 2027 : 28, 29, 30, 31 et 4 (le vendredi 1er janvier est férié)
            var days = SprintsController.CountWorkingDays(new DateTime(2026, 12, 28), new DateTime(2027, 1, 4));
            Assert.Equal(5, days);
        }

        [Fact]
        public void EndBeforeStart_ReturnsZero()
        {
            var days = SprintsController.CountWorkingDays(new DateTime(2026, 10, 20), new DateTime(2026, 10, 12));
            Assert.Equal(0, days);
        }
    }
}