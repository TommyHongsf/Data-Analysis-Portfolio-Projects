
-- Select Data to be used
Select Location, Date, total_cases, new_cases, total_deaths, population
From CovidAnalysisProject.dbo.CovidDeaths
order by 1, 2

-- Looking at total cases vs total deaths
-- Shows likelihood of dying if contracted Covid in the US
Select Location, Date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS PercentOfDeath
From CovidAnalysisProject.dbo.CovidDeaths
where Location like '%states%'
order by 1, 2

-- Looking at total cases vs population
-- Shows percentage of population that contracted Covid
Select Location, Date, Population, total_cases,  (total_cases/population)*100 AS PercentOfPopulationInfected
From CovidAnalysisProject.dbo.CovidDeaths
where Location like '%states%' 
order by 1, 2

-- Looking at countries with highest infection rate vs population
Select Location, Population, MAX(total_cases) AS HighestInfectionCount, MAX(total_cases/population)*100 AS PercentOfInfection
From CovidAnalysisProject.dbo.CovidDeaths
Where continent is not null
Group by Location, Population
Order by PercentOfInfection DESC


-- Looking at countries with highest death count
Select Location, MAX(cast(total_deaths as int)) AS TotalDeathCount
From CovidAnalysisProject.dbo.CovidDeaths
Where continent is not null
Group by Location
Order by TotalDeathCount DESC



-- Breaking it down by continent -- 

-- Showing continents with the highest death count per population
Select Continent, MAX(cast(total_deaths as int)) AS TotalDeathCount
From CovidAnalysisProject.dbo.CovidDeaths
Where Continent is not null
Group by Continent
Order by TotalDeathCount DESC

-- Global numbers
Select SUM(new_cases) AS TotalCases, SUM(cast(new_deaths as int)) AS TotalDeaths, 
	SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentage
From CovidAnalysisProject.dbo.CovidDeaths
Where continent is not null
order by 1, 2

-- Total global numbers
-- Global Numbers by Date
Select Date, SUM(new_cases) AS TotalCases, SUM(cast(new_deaths as int)) AS TotalDeaths
, SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentage
From CovidAnalysisProject.dbo.CovidDeaths
Where continent is not null
Group by Date



-- Looking at total population vs vaccinations
Select deaths.Continent, deaths.Location, deaths.Date, Population, vacs.New_vaccinations
, SUM(CONVERT(int, vacs.new_vaccinations)) OVER (Partition by deaths.Location Order by deaths.Location, 
  deaths.Date) AS RollingVaccinated
From CovidAnalysisProject.dbo.CovidDeaths AS deaths
Join CovidAnalysisProject.dbo.CovidVaccinations AS vacs
	On deaths.location = vacs.location
	and deaths.date = vacs.date
WHERE deaths.continent is not null
Order by 2, 3


-- Use CTE to use RollingVaccinated number and compare it to population

With PopulationVsVaccination(Continent, Location, Date, Population, New_vaccinations, RollingVaccinations)
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


-- Using Temp table to perform same calculation
Drop Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingVaccinations numeric
)

Insert into #PercentPopulationVaccinated
Select deaths.Continent, deaths.Location, deaths.Date, Population, vacs.New_vaccinations
, SUM(CONVERT(int, vacs.new_vaccinations)) OVER (Partition by deaths.Location Order by deaths.Location, 
  deaths.Date) AS RollingVaccinated
From CovidAnalysisProject.dbo.CovidDeaths AS deaths
Join CovidAnalysisProject.dbo.CovidVaccinations AS vacs
	On deaths.location = vacs.location
	and deaths.date = vacs.date
WHERE deaths.continent is not null


Select *, (RollingVaccinations/population)*100 As PercentVaccinated
From #PercentPopulationVaccinated
Order by 2, 3



-- Create View to store data for later visualizations

-- Rolling vaccinations vs population
Create View PercentagePopulationVaccinated AS 
Select deaths.Continent, deaths.Location, deaths.Date, Population, vacs.New_vaccinations
, SUM(CONVERT(int, vacs.new_vaccinations)) OVER (Partition by deaths.Location Order by deaths.Location, 
  deaths.Date) AS RollingVaccinated
From CovidAnalysisProject.dbo.CovidDeaths AS deaths
Join CovidAnalysisProject.dbo.CovidVaccinations AS vacs
	On deaths.location = vacs.location
	and deaths.date = vacs.date
WHERE deaths.continent is not null

CREATE VIEW PercentPopulationCases AS
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



