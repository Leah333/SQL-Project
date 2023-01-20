SELECT TOP 5 *
FROM master.dbo.CovidDeaths

SELECT TOP 5*
FROM master.dbo.CovidVaccinations

SELECT location,date,total_cases,new_cases,total_deaths,population
FROM master.dbo.CovidDeaths
WHERE continent is not NULL
order by 1,2

--change column type for accuracy of next calculations
ALTER TABLE master.dbo.CovidDeaths
ALTER COLUMN total_deaths FLOAT

ALTER TABLE master.dbo.CovidDeaths
ALTER COLUMN total_cases FLOAT

--Total cases vs Total deaths
--What is the likelihood of dying if one contracts Covid-19 (in the United States)?
SELECT location,date,total_cases,total_deaths,(total_deaths/total_cases)*100 as PercentageofDeaths
FROM master.dbo.CovidDeaths
Where location like '%states%'
and continent is not NULL
order by 1,2
--As of April 2021, if one got infeccted with Covid-19 their chance of dying was 1.7814% 

--Total cases vs Population
--What percentage of the population has Covid-19 in the United States?

SELECT location,date,population,total_cases,(total_cases/population)*100 as PercentagepopulationInfected
FROM master.dbo.CovidDeaths
Where location like '%states%'
and continent is not NULL
order by 1,2

--Countries with highest infection count compared to population
--What percentage of your  population has gotten COVID?
SELECT location,population,MAX(total_cases) as HighestInfectionCount,(MAX(total_cases/population))*100 as PercentagePopulationInfected
FROM master.dbo.CovidDeaths
WHERE continent is not NULL
Group by location,population
order by PercentagePopulationInfected DESC

--Countries with  highest  death count per population
SELECT location, MAX(total_deaths) as TotalDeathCount
FROM master.dbo.CovidDeaths
WHERE continent is not NULL
Group by location
order by TotalDeathCount DESC
--United States has the highest death count as of April 2021

--Classify by continent- continent with highest death count
SELECT continent, MAX(total_deaths) as TotalDeathCount
FROM master.dbo.CovidDeaths
WHERE continent is not NULL
Group by continent
order by TotalDeathCount DESC

--GLOBAL NUMBERS(Not divided up into locations/continents)
ALTER TABLE master.dbo.CovidDeaths
ALTER COLUMN new_cases FLOAT

ALTER TABLE master.dbo.CovidDeaths
ALTER COLUMN new_deaths FLOAT

--Daily cases in the world, daily deaths, death percentage
SELECT date,SUM(new_cases) as totalDailyCases, SUM(new_deaths) as TotalDailyDeaths,SUM(new_deaths)/SUM(new_cases) *100 as DeathPercentage
FROM master.dbo.CovidDeaths
WHERE continent is not NULL
Group by date
order by 1,2

--Total cases, deaths, and death percentage in the world as of April  2021
SELECT SUM(new_cases) as totalCases, SUM(new_deaths) as TotalDeaths,SUM(new_deaths)/SUM(new_cases) *100 as DeathPercentage
FROM master.dbo.CovidDeaths
WHERE continent is not NULL
order by 1,2


--Join Covid deaths table and Vaccinations table
--Compare population versus vaccinations

Select deaths.continent, deaths.location, deaths.date, deaths.population, vac.new_vaccinations
FROM master.dbo.CovidDeaths deaths
Join master.dbo.CovidVaccinations vac 
    On deaths.location = vac.location 
    and deaths.date = vac.date
WHERE deaths.continent is not NULL
order by 2,3

--Find running total of vaccinations per location daily as new people get vaccinated daily
ALTER TABLE master.dbo.CovidVaccinations
ALTER COLUMN new_vaccinations FLOAT

Select deaths.continent, deaths.location, deaths.date, deaths.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (Partition by deaths.location Order by CONVERT(nvarchar(255),deaths.location), deaths.date) as RollingCountOfPeoplevaccinated
FROM master.dbo.CovidDeaths deaths
Join master.dbo.CovidVaccinations vac 
    On deaths.location = vac.location 
    and deaths.date = vac.date
WHERE deaths.continent is not NULL
order by 2,3

--Rolling perccentage of people vaccinated against population per country
--CTE

With PopvsVac (continent,location,date,population,new_vaccinations, RollingCountOfPeoplevaccinated)
as
(
Select deaths.continent, deaths.location, deaths.date, deaths.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (Partition by deaths.location Order by CONVERT(nvarchar(255),deaths.location), deaths.date) as RollingCountOfPeoplevaccinated
FROM master.dbo.CovidDeaths deaths
Join master.dbo.CovidVaccinations vac 
    On deaths.location = vac.location 
    and deaths.date = vac.date
WHERE deaths.continent is not NULL

)
Select *, (RollingCountOfPeoplevaccinated/Population)*100 as RollingVaccinatedPercentage
From PopvsVac

--TEMP TABLE

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingCountOfPeoplevaccinated numeric

)
Insert into #PercentPopulationVaccinated
Select deaths.continent, deaths.location, deaths.date, deaths.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (Partition by deaths.location Order by CONVERT(nvarchar(255),deaths.location), deaths.date) as RollingCountOfPeoplevaccinated
FROM master.dbo.CovidDeaths deaths
Join master.dbo.CovidVaccinations vac 
    On deaths.location = vac.location 
    and deaths.date = vac.date
WHERE deaths.continent is not NULL

Select *, (RollingCountOfPeoplevaccinated/Population)*100 as RollingVaccinatedPercentage
From #PercentPopulationVaccinated

--Creating  views
GO
Create View PercentPopulationVaccinated as 
Select deaths.continent, deaths.location, deaths.date, deaths.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (Partition by deaths.location Order by CONVERT(nvarchar(255),deaths.location), deaths.date) as RollingCountOfPeoplevaccinated
FROM master.dbo.CovidDeaths deaths
Join master.dbo.CovidVaccinations vac 
    On deaths.location = vac.location 
    and deaths.date = vac.date
WHERE deaths.continent is not NULL


GO
Create View DeathPercentage as

SELECT date,SUM(new_cases) as totalDailyCases, SUM(new_deaths) as TotalDailyDeaths,SUM(new_deaths)/SUM(new_cases) *100 as DeathPercentage
FROM master.dbo.CovidDeaths
WHERE continent is not NULL
Group by date
--order by 1,2





