SELECT * FROM PortfolioProject..CovidVaccinations;

--Wrote inner join connecting CovidDeath and CovidVaccination tables. 
SELECT de.continent, de.location, de.date, de.population, va.new_vaccinations
FROM PortfolioProject..CovidDeaths AS de INNER JOIN PortfolioProject..CovidVaccinations AS va 
	ON de.date = va.date AND de.location = va.location
WHERE va.continent IS NOT NULL 

--Created a CTE for Cumulative Vaccination. This looks at the total population vs vaccinations.
WITH CTE_PopvsVac (Continent, Location, Date, Population, New_Vaccinations, Cumulative_Vaccinations) 
AS (
SELECT de.continent, de.location, de.date, de.population, va.new_vaccinations, 
	(Sum(Cast(va.new_vaccinations AS bigint)) OVER (Partition BY de.Location ORDER BY de.Location, de.Date)) AS Cumulative_Vaccinations
FROM PortfolioProject..CovidDeaths AS de INNER JOIN PortfolioProject..CovidVaccinations AS va 
	ON de.date = va.date AND de.location = va.location
WHERE va.continent IS NOT NULL 
)
SELECT *, Round((Cumulative_Vaccinations/Population)*100, 2) AS Percent_Vaccinated FROM CTE_PopvsVac;


--Created a Temp Table for the same purpose as the CTE above.
DROP TABLE IF EXISTS #PercentofPopulationVaccinated;
CREATE TABLE #PercentofPopulationVaccinated (
Continent NCHAR(255) NOT NULL,
Location NCHAR(255) NOT NULL,
Date datetime,
Population bigint,
New_Vaccinations int,
Cumulative_Vaccinations bigint
);
INSERT INTO #PercentofPopulationVaccinated
SELECT de.continent, de.location, de.date, de.population, va.new_vaccinations, 
	(Sum(Cast(va.new_vaccinations AS bigint)) OVER (Partition BY de.Location ORDER BY de.Location, de.Date)) AS Cumulative_Vaccinations
FROM PortfolioProject..CovidDeaths AS de INNER JOIN PortfolioProject..CovidVaccinations AS va 
	ON de.date = va.date AND de.location = va.location
WHERE va.continent IS NOT NULL
;

SELECT *, Round((Cumulative_Vaccinations/Population)*100, 2) FROM #PercentofPopulationVaccinated;

--Created a View for later visualization.
GO
CREATE VIEW PercentPopulationVaccinated
AS
SELECT de.continent, de.location, de.date, de.population, va.new_vaccinations, 
	(Sum(Cast(va.new_vaccinations AS bigint)) OVER (Partition BY de.Location ORDER BY de.Location, de.Date)) AS Cumulative_Vaccinations
FROM PortfolioProject..CovidDeaths AS de INNER JOIN PortfolioProject..CovidVaccinations AS va 
	ON de.date = va.date AND de.location = va.location
WHERE va.continent IS NOT NULL;
GO

SELECT * FROM PercentPopulationVaccinated;

-- Use below if running again, to be able to create the VIEW again
-- DROP VIEW IF EXISTS PercentPopulationVaccinated;