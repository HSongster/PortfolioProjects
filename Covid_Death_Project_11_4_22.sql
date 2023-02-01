/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

-- Select Data that we are going to be starting with

SELECT location, entry_date, total_cases, new_cases, total_deaths, population
FROM public.working_covid_deaths
WHERE continent IS NOT NULL
ORDER BY 1,2;

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

SELECT  Location, entry_date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM public.working_covid_deaths
WHERE location LIKE 'United States'
AND continent IS NOT NULL
ORDER BY 1,2;

--Total Cases vs Population
--Shows what percentage of population infected with Covid

SELECT location, entry_date,population, total_cases, (total_cases/population)*100 as PercentPopulationInfected
FROM public.working_covid_deaths
WHERE location LIKE 'United States'
ORDER BY 1,2;

--Countries with Highest Infection Rate compared to Population

SELECT  Location, Population, MAX(total_cases) AS HighestInfectionCount,  Max((total_cases/population))*100 AS PercentPopulationInfected
FROM public.working_covid_deaths
WHERE total_cases IS NOT NULL
AND population IS NOT NULL
GROUP BY location, Population
ORDER BY PercentPopulationInfected DESC;

--Countries with Highest Death Count per Population

SELECT location, MAX(Total_deaths) AS TotalDeathCount
FROM public.working_covid_deaths
WHERE continent IS NOT NULL
AND total_deaths IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;

--BREAKING THINGS DOWN BY CONTINENT
--Showing continents with the hightest death count per population

SELECT  continent, MAX(CAST(Total_deaths AS int)) AS TotalDeathCount
FROM public.working_covid_deaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BYTotalDeathCount DESC;

--GLOBAL NUMBERS


SELECT  SUM(new_cases) AS total_cases, SUM(cast(new_deaths AS int)) AS total_deaths, SUM(cast(new_deaths AS int))/SUM(New_Cases)*100 AS DeathPercentage
FROM public.working_covid_deaths
WHERE continent IS NOT NULL
--Group By entry_date
ORDER BY 1,2;

--Total Population vs Vaccincations
--Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT  dea.continent, dea.location, dea.entry_date, dea.population, vac.new_vaccinations
, SUM(Cast(vac.new_vaccinations AS integer)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.entry_date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM public.working_covid_deaths dea
JOIN public.working_covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.entry_date = vac.entry_date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;

--Using CTE to perform Calculations on Partition By in previous query

With PopvsVac (continent, location, entry_date, population, new_vaccination, RollingPeopleVaccinated)
AS
(
SELECT  dea.continent, dea.location, dea.entry_date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS integer)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.entry_date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM public.working_covid_deaths dea
JOIN public.working_covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.entry_date = vac.entry_date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3
);

SELECT *, (Rollingpeoplevaccinated/population)*100
From PopvsVac;

--Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE if exists PercentPopulationVaccinated
CREATE TEMPORARY TABLE PercentPopulationVaccinated
(Continent varchar(255),
	Locaction varchar (255),
	Entry_date date,
	Population numeric,
	New_Vaccinations numeric,
	RollingPeopleVaccinted numeric
	);

INSERT INTO PercentPopulationVaccinated
SELECT  dea.continent, dea.location, dea.entry_date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS integer)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.entry_date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM public.working_covid_deaths dea
JOIN public.working_covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.entry_date = vac.entry_date;
--where dea.continent is not null 
--order by 2,3

SELECT * --, (RollingPeopleVaccinated/Population)*100
FROM PercentPopulationVaccinated;

--Creating Views to store data for later visualization

CREATE VIEW PercentPopulationVaccinated AS
SELECT  dea.continent, dea.location, dea.entry_date, dea.population, vac.new_vaccinations
, SUM(Cast(vac.new_vaccinations AS integer)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.entry_Date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM public.working_covid_deaths dea
JOIN public.working_covid_vaccinations vac
	On dea.location = vac.location
	AND dea.entry_date = vac.entry_date
WHERE dea.continent IS NOT NULL;

CREATE VIEW United_States_Death_Percentage AS
SELECT  Location, entry_date, total_cases,total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM public.working_covid_deaths
WHERE location LIKE 'United States'
and continent IS NOT NULL
ORDER BY 1,2;

CREATE VIEW TotalPopulation_VS_Vaccinated AS
SELECT  dea.continent, dea.location, dea.entry_date, dea.population, vac.new_vaccinations
, SUM(Cast(vac.new_vaccinations AS integer)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.entry_date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM public.working_covid_deaths dea
JOIN public.working_covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.entry_date = vac.entry_date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;


CREATE VIEW ContinentalDeathRate AS
SELECT continent, MAX(cast(Total_deaths AS int)) AS TotalDeathCount
FROM public.working_covid_deaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;


--Queries needed for Tableau Visualizations

-- 1. 

SELECT SUM(new_cases) AS total_cases, SUM(cast(new_deaths AS int)) AS total_deaths, SUM(cast(new_deaths ASint))/SUM(New_Cases)*100 AS DeathPercentage
From public.working_covid_deaths
--Where location like '%states%'
WHERE continent IS NOT null 
--Group By date
ORDER BY 1,2;

-- Just a double check based off the data provided
-- numbers are extremely close so I will keep them - The Second includes "International"  Location


--Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
--From public.working_covid_deaths
----Where location like '%states%'
--where location = 'World'
----Group By date
--order by 1,2


-- 2. 

-- I took these out as they are not inluded in the above queries and want to stay consistent
-- European Union is part of Europe

SELECT location, SUM(cast(new_deaths AS int)) AS TotalDeathCount
FROM public.working_covid_deaths
--Where location like '%states%'
WHERE continent IS null 
AND location NOT IN ('World', 'European Union', 'International')
GROUP BY location
ORDER BY TotalDeathCount DESC;


-- 3.

SELECT Location, Population, MAX(total_cases) AS HighestInfectionCount,  Max((total_cases/population))*100 AS PercentPopulationInfected
FROM public.working_covid_deaths
--Where location like '%states%'
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC;


-- 4.


SELECT Location, Population,date, MAX(total_cases) AS HighestInfectionCount,  Max((total_cases/population))*100 AS PercentPopulationInfected
FROM public.working_covid_deaths
--Where location like '%states%'
GROUP BY Location, Population, date
ORDER BY PercentPopulationInfected DESC;
