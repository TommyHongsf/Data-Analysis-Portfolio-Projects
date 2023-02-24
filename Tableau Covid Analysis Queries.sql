/*

Covid 19 Data Exploration pt. 2

Queries used for data to be imported and visualized in Tableau

*/

-- Global numbers of death count per population
Select SUM(new_cases) AS TotalCases, SUM(cast(new_deaths as int)) AS TotalDeaths, 
	SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentage
From CovidAnalysisProject.dbo.CovidDeaths
Where continent is not null
Order by 1, 2


-- Total deaths per location
-- excludes locations shown as World, European Union, and International
Select location, SUM(cast(new_deaths as int)) AS TotalDeaths
From CovidAnalysisProject.dbo.CovidDeaths
Where continent is null
and location not in ('World', 'European Union', 'International')
Group by location
Order by TotalDeaths Desc


-- Total cases and infected percentage per population 
Select Location, Population, Max(total_cases) AS HighestInfectionCount,  MAX((total_cases/population))*100 AS PercentOfPopulationInfected
From CovidAnalysisProject.dbo.CovidDeaths
Group by Location, Population
Order by PercentOfPopulationInfected Desc

-- -- Total cases and infected percentage per population by date
Select Location, Population, Date, MAX(total_cases) AS HighestInfectionCount,  MAX((total_cases/population))*100 AS PercentOfPopulationInfected
From CovidAnalysisProject.dbo.CovidDeaths
Group by Location, Population, Date
Order by PercentOfPopulationInfected Desc
