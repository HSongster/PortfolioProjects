/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

Select *
From public."Covid_Death_Data_1"
Where continent is not null 
order by 3,4


-- Select Data that we are going to be starting with

Select location, entry_date, total_cases, new_cases, total_deaths, population
From public."Covid_Death_Data_1"
Where continent is not null 
order by 1,2


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

Select Location, entry_date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From public."Covid_Death_Data_1"
WHERE location like 'United States%'
and continent is not null
order by 1,2


--Total Cases vs Population
--Shows what percentage of population infected with Covid

Select location, entry_date, population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From public."Covid_Death_Data_1"
WHERE location like 'United States%'
order by 1,2


--Countries with Highest Infection Rate compared to Population

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From public."Covid_Death_Data_1"
WHERE total_cases is not null
and population is not null
Group by location, Population
order by PercentPopulationInfected desc


--Countries with Highest Death Count per Population

Select location, MAX(Total_deaths) as TotalDeathCount
From public."Covid_Death_Data_1"
Where continent is not null 
and total_deaths is not null
Group by location
order by TotalDeathCount desc


--BREAKING THINGS DOWN BY CONTINENT
--Showing continents with the hightest death count per population

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From public."Covid_Death_Data_1"
Where continent is not null 
Group by continent
order by TotalDeathCount desc


--GLOBAL NUMBERS


Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From public."Covid_Death_Data_1"
where continent is not null 
--Group By entry_date
order by 1,2


--Total Population vs Vaccincations
--Shows Percentage of Population that has recieved at least one Covid Vaccine

Select dea.continent, dea.location, dea.entry_date, dea.population, vac.new_vaccinations
, SUM(Cast(vac.new_vaccinations as integer)) OVER (Partition by dea.location Order by dea.location, dea.entry_date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From public."Covid_Death_Data_1" dea
Join public."Covid_Vaccination_Data" vac
	On dea.location = vac.location
	and dea.entry_date = vac.entry_date
where dea.continent is not null
order by 2,3


--Using CTE to perform Calculations on Partition By in previous query

With PopvsVac (continent, location, entry_date, population, new_vaccination, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.entry_date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations as integer)) OVER (Partition by dea.Location Order by dea.location, dea.entry_date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From public."Covid_Death_Data_1" dea
Join public."Covid_Vaccination_Data" vac
	On dea.location = vac.location
	and dea.entry_date = vac.entry_date
where dea.continent is not null 
order by 2,3
)
Select*, (Rollingpeoplevaccinated/population)*100
From PopvsVac


--Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE if exists PercentPopulationVaccinated_2
CREATE TEMPORARY TABLE PercentPopulationVaccinated_2
(Continent varchar(255),
	Locaction varchar (255),
	Entry_date date,
	Population numeric,
	New_Vaccinations numeric,
	RollingPeopleVaccinted numeric
	)

INSERT INTO PercentPopulationVaccinated_2
Select dea.continent, dea.location, dea.entry_date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations as integer)) OVER (Partition by dea.Location Order by dea.location, dea.entry_date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From public."Covid_Death_Data_1" dea
Join public."Covid_Vaccination_Data" vac
	On dea.location = vac.location
	and dea.entry_date = vac.entry_date
--where dea.continent is not null 
--order by 2,3

SELECT *,(RollingPeopleVaccinated/Population)*100
FROM public.PercentPopulationVaccinated

--Creating View to store data for later visualization

Create View PercentPopulationVaccinated_1 as
Select dea.continent, dea.location, dea.entry_date, dea.population, vac.new_vaccinations
, SUM(Cast(vac.new_vaccinations as integer)) OVER (Partition by dea.Location Order by dea.location, dea.entry_Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From public."Covid_Death_Data_1" dea
Join public."Covid_Vaccination_Data" vac
	On dea.location = vac.location
	and dea.entry_date = vac.entry_date
where dea.continent is not null 

Create View United_States_Death_Percentage as
Select Location, entry_date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From public."Covid_Death_Data_1"
WHERE location like 'United States%'
and continent is not null
order by 1,2

Create View TotalPopulation_VS_Vaccinated as
Select dea.continent, dea.location, dea.entry_date, dea.population, vac.new_vaccinations
, SUM(Cast(vac.new_vaccinations as integer)) OVER (Partition by dea.location Order by dea.location, dea.entry_date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From public."Covid_Death_Data_1" dea
Join public."Covid_Vaccination_Data" vac
	On dea.location = vac.location
	and dea.entry_date = vac.entry_date
where dea.continent is not null
order by 2,3


Create View ContinentalDeathRate as
Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From public."Covid_Death_Data_1"
Where continent is not null 
Group by continent
order by TotalDeathCount desc