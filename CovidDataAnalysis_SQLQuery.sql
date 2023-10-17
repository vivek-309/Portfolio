/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

SELECT *
FROM Portfolio_Project.dbo.CovidDeaths$
ORDER BY location,  date

SELECT * 
FROM Portfolio_Project..CovidVaccinations$
ORDER BY 3,4

SELECT location, date, total_cases,new_cases, total_deaths, population
FROM Portfolio_Project..CovidDeaths$
ORDER BY 1,2

--Showing Total Cases vs Total Deaths--

SELECT location, date, total_cases, total_deaths, ROUND(CONVERT(float, total_deaths)/CONVERT (float, total_cases)*100,2) AS Death_Percentage
FROM Portfolio_Project..CovidDeaths$
WHERE location = 'India' AND continent IS NOT NULL
ORDER BY 1,2;

--Showing Total Cases vs Population--

SELECT location, date, population, total_cases, ROUND(CONVERT(float, total_cases)/CONVERT (float, population)*100,2) AS Infected_Percentage
FROM Portfolio_Project..CovidDeaths$
WHERE location = 'India' AND continent IS NOT NULL
ORDER BY 1,2;

--Countries with Highest Infecttion Rate--

SELECT location, population, MAX(total_cases) as Highest_Infection_Count, ROUND(MAX((total_cases/population))*100,2) as Infected_Percentage 
FROM Portfolio_Project..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY Infected_Percentage DESC;

--Countries with Highest Death Rate--

SELECT location, population, MAX(CAST(total_deaths AS int)) as Highest_Death_Count, ROUND(MAX((total_deaths/population))*100,2) as Death_Percentage 
FROM Portfolio_Project..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY Death_Percentage DESC;

--Continents with Highest Death Rate--

SELECT continent, MAX(CAST(total_deaths AS int)) as Highest_Death_Count, ROUND(MAX((total_deaths/population))*100,2) as Death_Percentage 
FROM Portfolio_Project..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY Death_Percentage DESC;

--Global Numbers--

SELECT date,SUM(new_cases) as Total_Cases,SUM(CAST(new_deaths as int)) as Total_Deaths,
    CASE
        WHEN SUM(new_cases) = 0 THEN NULL -- Handle division by zero
        ELSE SUM(CONVERT(FLOAT, new_deaths)) / SUM(new_cases) * 100
    END as Death_Percentage
FROM Portfolio_Project..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date;

--Overall Global Numbers--

SELECT SUM(new_cases) as Total_Cases,SUM(CAST(new_deaths as int)) as Total_Deaths,
    CASE
        WHEN SUM(new_cases) = 0 THEN NULL -- Handle division by zero
        ELSE ROUND(SUM(CONVERT(FLOAT, new_deaths)) / SUM(new_cases) * 100,3)
    END as Death_Percentage
FROM Portfolio_Project..CovidDeaths$
WHERE continent IS NOT NULL;

--Looking at Total Population vs Vaccinations--

SELECT  d.continent, d.location, d.date, D.population, V.new_vaccinations,
SUM(CONVERT(int, V.new_vaccinations)) OVER ( PARTITION BY D.location ORDER BY D.location, D.date) AS RollingPeopleVaccinacated
FROM Portfolio_Project..CovidVaccinations$ V
	JOIN Portfolio_Project..CovidDeaths$ D
	ON D.date =  V.date
	AND D.date = V.date
	WHERE D.continent IS NOT NULL
	ORDER BY 2,3;

--Using CTE Query--

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
FROM Portfolio_Project..CovidDeaths$ dea
JOIN Portfolio_Project..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null 
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac

--Using Temp Table to perform Calculation on Partition By in previous query--

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
--WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated

--Creating View to store data for later visualizations--

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM Portfolio_Project..CovidDeaths$ dea
JOIN Portfolio_Project..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
