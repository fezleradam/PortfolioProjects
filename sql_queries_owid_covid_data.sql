-- Checking the tables

SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3, 4;

SELECT *
FROM PortfolioProject..CovidVaccination
ORDER BY 3, 4;


-- Creating view to store data for further queries

IF EXISTS (SELECT * FROM sys.views WHERE name = 'CovidCasesWorldwide' AND type = 'V')
    DROP VIEW CovidCasesWorldwide;
	GO

CREATE VIEW CovidCasesWorldwide AS
SELECT location, population, CAST(date AS DATE) AS date, new_cases, total_cases, total_deaths
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
-- ORDER BY location, date;


-- Showing the probability of dying if you contract COVID-19 in Hungary

SELECT location, CAST(date AS DATE), total_cases, total_deaths, ROUND((total_deaths/total_cases) * 100, 2) AS death_percentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL AND location LIKE 'Hungary'
ORDER BY date;


-- Showing what percentage of population were infected by COVID-19 in Hungary

SELECT location, CAST(date AS DATE), population, total_cases, ROUND((total_cases/population) * 100, 2) AS infection_percentage
FROM PortfolioProject..CovidDeaths
WHERE total_cases IS NOT NULL AND continent IS NOT NULL AND location = 'Hungary'
ORDER BY date;


-- Showing the countries with the highest infection rate compared to their population

SELECT location, population, MAX(total_cases) AS highest_infection_count, ROUND(MAX((total_cases/population)) * 100, 2) AS percent_population_infected
FROM PortfolioProject..CovidDeaths
WHERE total_cases IS NOT NULL AND continent IS NOT NULL
GROUP BY location, population
ORDER BY percent_population_infected DESC;


-- Showing the number of deaths per countries

SELECT location, MAX(total_deaths) AS total_death_count
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC;


-- Showing the number of deaths per continents

SELECT continent, SUM(new_deaths) AS total_death_count
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count DESC;


-- Showing the total deaths worldwide using a subquery with inline view (countries)

SELECT SUM(total_death_count) AS total_deaths_worldwide
FROM (
  SELECT location, MAX(total_deaths) AS total_death_count
  FROM PortfolioProject..CovidDeaths
  WHERE continent IS NOT NULL
  GROUP BY location
) AS subquery_total_deaths;


-- Showing the total deaths worldwide using CTE (countries)

WITH cte_total_deaths AS (
  SELECT location, MAX(total_deaths) AS total_death_count
  FROM PortfolioProject..CovidDeaths
  WHERE continent IS NOT NULL
  GROUP BY location
)
SELECT SUM(total_death_count) AS total_deaths_worldwide
FROM cte_total_deaths;


-- Showing the number of deaths worldwide (continents)

WITH cte_total_deaths_per_continents AS (
  SELECT continent, SUM(new_deaths) AS total_death_count
  FROM PortfolioProject..CovidDeaths
  WHERE continent IS NOT NULL
  GROUP BY continent
)
SELECT SUM(total_death_count) AS total_deaths_worldwide
FROM cte_total_deaths_per_continents;


-- Calculating total new cases and new deaths per day, along with the death percentage per day

SELECT CAST(date AS DATE), SUM(new_cases) AS total_new_cases_per_day, SUM(new_deaths) AS total_new_deaths_per_day, ROUND(SUM(new_deaths)/SUM(new_cases) * 100, 2) AS death_percentage_per_day
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL AND new_cases > 0
GROUP BY date
ORDER BY date;


-- Showing the total population vs vaccinations

SELECT dea.continent, dea.location, CAST(dea.date AS DATE), dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccination AS vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND new_vaccinations IS NOT NULL -- AND dea.location LIKE 'Hungary'
ORDER BY 2,3

-- Showing the total population vs vaccinations - CTE solution

WITH pop_vs_vac (continent, location, date, population, new_vaccination, rolling_people_vaccinated)
AS
(
SELECT dea.continent, dea.location, CAST(dea.date AS DATE), dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM PortfolioProject..CovidDeaths AS dea
Join PortfolioProject..CovidVaccination AS vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL -- AND dea.location LIKE 'Hungary'
)
SELECT *, (rolling_people_vaccinated/population) * 100
FROM pop_vs_vac;


-- Showing the total population vs vaccinations - Temp table solution

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent NVARCHAR(255),
location NVARCHAR(255),
date DATE,
population FLOAT,
new_vaccinations FLOAT,
rolling_people_vaccinated FLOAT
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) over (partition by dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccination AS vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND new_vaccinations IS NOT NULL -- AND dea.location LIKE 'Hungary'

SELECT *, ROUND((rolling_people_vaccinated/population) * 100, 2) AS vaccinated_ratio
FROM #PercentPopulationVaccinated;

-- Creating View to store data for visualizations

IF EXISTS (SELECT * FROM sys.views WHERE name = 'PercentPopulationVaccinated' AND type = 'V')
    DROP VIEW PercentPopulationVaccinated;
	GO

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccination AS vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL -- AND dea.location LIKE 'Hungary'