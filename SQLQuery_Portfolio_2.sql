/*

Covid 19 Data Exploration

*/

SELECT *
From PortfolioProject..CovidDeaths
Where continent is not null
Order by 3,4


SELECT Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
Where continent is not null
Order by 1,2

-- Total cases vs total deaths
-- Casting total_deaths as float, otherwise result of int division = 0

SELECT Location, date, total_cases, total_deaths, CAST(total_deaths AS FLOAT) / total_cases*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where continent is not null
Order by 1,2


-- Total cases vs total deaths in the US
-- Likelyhood of death if you contract Covid in the US
SELECT Location, date, total_cases, total_deaths, CAST(total_deaths AS FLOAT) / total_cases*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where location like '%states%'
and continent is not null
Order by 1,2

-- Total cases vs population
-- Percentage of population that got Covid
SELECT Location, date, population, total_cases, CAST(total_cases AS FLOAT) / population*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
Where location like '%states%'
and continent is not null
Order by 1,2

-- Countries having the highest infection rates compared to population
SELECT Location, population, MAX(total_cases) as HighestInfectionCount, CAST(MAX(total_cases) AS FLOAT) / population*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
Where continent is not null
Group by Location, population
Order by PercentPopulationInfected desc

-- Countries having highest death count per population
SELECT Location, MAX(total_deaths) AS TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is not null
Group by Location
Order by TotalDeathCount desc

-- Highest death count by continent
-- This is the right way:
SELECT location, MAX(total_deaths) AS TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is null
Group by location
Order by TotalDeathCount desc


-- Global numbers: death percentage by date
SELECT date, SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(cast(new_deaths as float))/SUM(new_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where continent is not null
Group by date
Order by 1,2

-- Global numbers: death percentage (FOR TABLEAU)
SELECT SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(cast(new_deaths as float))/SUM(new_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where continent is not null
Order by 1,2


-- Vaccinations
SELECT *
From PortfolioProject..CovidVaccinations

-- Join the two tables
SELECT *
From PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    and dea.date = vac.date

-- Total population vs vaccinations
-- Percentage of population that has recived at least one Covid vaccine
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
From PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    and dea.date = vac.date
WHERE dea.continent is not NULL
Order by 2,3

-- Rolling number of vaccinations: adding up vaccinations by day for each country
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (Partition by dea.location
order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    and dea.date = vac.date
WHERE dea.continent is not NULL
Order by 2,3

-- Using CTE for calculation on Partition by
With PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (Partition by dea.location
order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    and dea.date = vac.date
WHERE dea.continent is not NULL
)
SELECT *, RollingPeopleVaccinated / population * 100
From PopvsVac


-- Temp table to perform calculation on Partition by
DROP table if exists #PercentPopulationVaccinated
Create table #PercentPopulationVaccinated
(
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
)

Insert into #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (Partition by dea.location
order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    and dea.date = vac.date

SELECT *, RollingPeopleVaccinated / population * 100
From #PercentPopulationVaccinated

-- Creating view to store data for future visualizations
CREATE VIEW PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (Partition by dea.location,
dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    and dea.date = vac.date
WHERE dea.continent is not NULL



-- Queries for tableau visualization

-- Query 1
Select SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, 
SUM(cast(new_deaths as float))/SUM(New_Cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
where continent is not null 
order by 1,2


-- Query 2
Select location, SUM(new_deaths) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is null 
and location not in ('World', 'European Union', 'International')
Group by location
order by TotalDeathCount desc


-- Query 3
Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max(CAST(total_cases as float)) /population *100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
Group by Location, Population
order by PercentPopulationInfected desc


-- Query 4
Select Location, Population,date, MAX(total_cases) as HighestInfectionCount,  Max(CAST(total_cases as float)) /population*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
Group by Location, Population, date
order by PercentPopulationInfected desc