SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY Location DESC, date DESC;


--Added calculated field for cumulative death percentage of those who got Covid. This looks specifically for United States
SELECT Location, date, total_cases, total_deaths, (Convert(float, total_deaths)/NULLIF(Cast(total_cases AS bigint), 0))*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE 'United S%'
ORDER BY Location, date;

--This looks at the top 20 highest percentage of infected people compared to the population in each country.
SELECT Top(20) Location, population, Max(total_cases) AS Infected, Max((Convert(bigint, total_cases)/population)*100) AS PercentageInfected
FROM PortfolioProject..CovidDeaths
GROUP BY Location, population
ORDER BY PercentageInfected DESC;

--This looks at the highest death count for each country. 
SELECT Location, Max(Convert(int, total_deaths)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE Continent IS NOT NULL 
GROUP BY Location
ORDER BY TotalDeathCount DESC;

--This determines the death percentage of all cases for each country. Null percentages are due to unreported population/death statistics.
SELECT Location, Round((Max(Cast(total_deaths AS float))/Max(Convert(float, total_cases)))*100, 2) AS [Death Percentage] 
FROM PortfolioProject..CovidDeaths
WHERE Continent IS NOT NULL
GROUP BY Location
ORDER BY [Death Percentage] DESC;

--Checks total death count for each continent
SELECT Continent, Max(Cast(total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE Continent IS NOT NULL
GROUP BY Continent
ORDER BY TotalDeathCount DESC;

--This checks for the sum of new cases for each day globally.
SELECT date, Sum(new_cases) AS GlobalCases, Sum(new_deaths) AS GlobalDeaths, Round((Sum(new_deaths)/NULLIF(Sum(new_cases), 0))*100, 2) AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE Continent IS NOT NULL
GROUP BY date
ORDER BY date;