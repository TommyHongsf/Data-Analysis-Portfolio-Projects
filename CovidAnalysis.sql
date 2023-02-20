/*

Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

-- Select data to be used
Select Location, Date, Total_cases, New_cases, Total_deaths, Population
From CovidAnalysisProject.dbo.CovidDeaths
Where continent is not null
Order by 1, 2


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if tested positive for Covid in the US
Select Location, Date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS PercentOfDeath
From CovidAnalysisProject.dbo.CovidDeaths
Where Location like '%states%'
Order by 1, 2

-- Total Cases vs Population
-- Shows percentage of population in the US infected with Covid
Select Location, Date, Population, total_cases,  (total_cases/population)*100 AS PercentOfPopulationInfected
From CovidAnalysisProject.dbo.CovidDeaths
Where Location like '%states%' 
Order by 1, 2

-- Countries with highest infection rate vs population
Select Location, Population, MAX(total_cases) AS TotalInfectionCount
, MAX(total_cases/population)*100 AS PercentOfInfection
From CovidAnalysisProject.dbo.CovidDeaths
Group by Location, Population
Order by PercentOfInfection DESC


-- Countries with highest death count compared to population
Select Location, MAX(cast(total_deaths as int)) AS TotalDeathCount
From CovidAnalysisProject.dbo.CovidDeaths
Where continent is not null
Group by Location
Order by TotalDeathCount DESC



-- Breaking it down by continent

-- Showing continents with the highest death count per population
Select Continent, MAX(cast(total_deaths as int)) AS TotalDeathCount
From CovidAnalysisProject.dbo.CovidDeaths
Where Continent is not null
Group by Continent
Order by TotalDeathCount DESC

-- Global numbers of death count per population
Select SUM(new_cases) AS TotalCases, SUM(cast(new_deaths as int)) AS TotalDeaths, 
	SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentage
From CovidAnalysisProject.dbo.CovidDeaths
Where continent is not null
Order by 1, 2

-- Global numbers of death count per population by date
Select Date, SUM(new_cases) AS TotalCases, SUM(cast(new_deaths as int)) AS TotalDeaths
, SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentage
From CovidAnalysisProject.dbo.CovidDeaths
Where continent is not null
Group by Date
Order by 1, 2



-- Total Population vs Vaccinations
-- Shows percentage of population that has recieved at least one Covid vaccine

Select deaths.Continent, deaths.Location, deaths.Date, Population, vacs.New_vaccinations
, SUM(CONVERT(int, vacs.new_vaccinations)) OVER (Partition by deaths.Location Order by deaths.Location, 
  deaths.Date) AS RollingVaccinated
From CovidAnalysisProject.dbo.CovidDeaths AS deaths
Join CovidAnalysisProject.dbo.CovidVaccinations AS vacs
	On deaths.location = vacs.location
	and deaths.date = vacs.date
WHERE deaths.continent is not null
Order by 2, 3


-- Use CTE to use RollingVaccinated number from previous query and compare it to population

With PopulationVsVaccination(Continent, Location, Date, Population, New_deaths, New_vaccinations, RollingVaccinations)
as
(
Select deaths.Continent, deaths.Location, deaths.Date, Population, vacs.New_vaccinations
, SUM(CONVERT(int, vacs.new_vaccinations)) OVER (Partition by deaths.Location Order by deaths.Location, 
  deaths.Date) AS RollingVaccinated
From CovidAnalysisProject.dbo.CovidDeaths AS deaths
Join CovidAnalysisProject.dbo.CovidVaccinations AS vacs
	On deaths.location = vacs.location
	and deaths.date = vacs.date
WHERE deaths.continent is not null
)
Select *, (RollingVaccinations/population)*100 As PercentVaccinated
From PopulationVsVaccination
Order by 2,3


-- Using Temp table to perform same calculation as CTE
Drop Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_deaths numeric,
New_vaccinations numeric,
RollingVaccinations numeric
)

Insert into #PercentPopulationVaccinated
Select deaths.Continent, deaths.Location, deaths.Date, Population, deaths.New_deaths, vacs.New_vaccinations
, SUM(CONVERT(int, vacs.new_vaccinations)) OVER (Partition by deaths.Location Order by deaths.Location, 
  deaths.Date) AS RollingVaccinated
From CovidAnalysisProject.dbo.CovidDeaths AS deaths
Join CovidAnalysisProject.dbo.CovidVaccinations AS vacs
	On deaths.location = vacs.location
	and deaths.date = vacs.date
WHERE deaths.continent is not null


Select *, (RollingVaccinations/population)*100 As PercentVaccinated
From #PercentPopulationVaccinated
Where location like '%states%'
Order by 2, 3



-- Create View to store data for later visualizations

-- Rolling vaccinations vs population
Create View PercentagePopulationVaccinated AS 
Select deaths.Continent, deaths.Location, deaths.Date, Population, deaths.New_deaths, vacs.New_vaccinations
, SUM(CONVERT(int, vacs.new_vaccinations)) OVER (Partition by deaths.Location Order by deaths.Location, 
  deaths.Date) AS RollingVaccinated
From CovidAnalysisProject.dbo.CovidDeaths AS deaths
Join CovidAnalysisProject.dbo.CovidVaccinations AS vacs
	On deaths.location = vacs.location
	and deaths.date = vacs.date
WHERE deaths.continent is not null

CREATE View PercentPopulationCases AS
-- View of total cases vs population
SELECT Location, Date, Population, Total_cases, (Total_cases/Population)*100 AS PercentPopultaionInfected
From CovidAnalysisProject.dbo.CovidDeaths
WHERE continent is not null

Create View DeathCountVsPopulation AS
-- Looking at countries with highest death count
Select continent, MAX(cast(total_deaths as int)) AS TotalDeathCount
From CovidAnalysisProject.dbo.CovidDeaths
Where continent is not null
Group by continent

Create View InfectionRateVsPopulation AS
-- Looking at countries with highest infection rate vs population
Select Location, Population, MAX(total_cases) AS HighestInfectionCount, MAX(total_cases/population)*100 AS PercentOfInfection
From CovidAnalysisProject.dbo.CovidDeaths
Where continent is not null
Group by Location, Population



