-- These queries are for Tableau

-- 1. This sums up all recorded cases and deaths for the global population, AS well AS the death rate. 

SELECT SUM(new_cases) AS total_cases, SUM(Cast(new_deaths AS int)) AS total_deaths, SUM(Cast(new_deaths AS int))/SUM(New_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null 


-- 2. 

-- We take these out as they are not inluded in the above queries and want to stay consistent
-- Note that European Union is part of Europe

SELECT location, SUM(Cast(new_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
--WHERE location like '%states%'
WHERE continent IS NULL 
AND location NOT IN ('World', 'European Union', 'International', 'High income', 'Upper middle income', 'Lower middle income', 'Low income')
GROUP BY location
ORDER BY TotalDeathCount DESC


-- 3. This looks at each nation and calculates their highest amount of cases, and the percent of the population that it represents. 

SELECT Location, Population, MAX(total_cases) AS HighestInfectionCount,  Max((total_cases/population))*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE location NOT IN ('World', 'European Union', 'International', 'High income', 'Upper middle income', 'Lower middle income', 'Low income')
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC


-- 4.This looks at the days which had the highest percent of population infected, and lists them in DESCending order. Note that the population is fixed,
--   so the percentage is scaling bASed off of the infection count.


SELECT Location, Population,date, MAX(total_cases) AS HighestInfectionCount,  Max((total_cases/population))*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE location NOT IN ('World', 'European Union', 'International', 'High income', 'Upper middle income', 'Lower middle income', 'Low income')
GROUP BY Location, Population, date
ORDER BY PercentPopulationInfected DESC