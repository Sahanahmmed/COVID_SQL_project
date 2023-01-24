SELECT * 
FROM Portfolio..covid_deaths
ORDER BY 3,4 ;

--SELECT *
--FROM Portfolio..covid_vaccinations
--ORDER BY 3, 4 ;

-- Select Data that we are going to be using

SELECT Location , date , total_cases , new_cases , total_deaths , population
FROM Portfolio..covid_deaths 
ORDER BY 1, 2 ;

-- Looking at total_cases vs total_deaths
-- Shows probability of dying if you contract covid in India

SELECT Location , date , total_cases , total_deaths , (total_deaths/total_cases)*100 as death_percentage
FROM Portfolio..covid_deaths 
WHERE location like '%India%'
ORDER BY 1, 2 ;


-- Looking at total_cases vs population
-- Shows what percentage of population got covid

SELECT Location , date ,  population , total_cases ,(total_cases/population)*100 as case_percentage
FROM Portfolio..covid_deaths 
WHERE location like '%India%'
ORDER BY 1, 2 ;

-- Finding countries with highest infection Rate compared to population

SELECT Location  ,  population ,MAX( total_cases) as highest_cases ,MAX(total_cases/population)*100 as case_percentage
FROM Portfolio..covid_deaths 
GROUP BY location , population
ORDER BY case_percentage desc ;

-- Finding Countries with highest Death count per population

SELECT Location  , MAX(cast( total_deaths as int)) as highest_death_cases 
FROM Portfolio..covid_deaths 
GROUP BY location 
ORDER BY highest_death_cases desc ;

-- Cleaning the data of location as continent to clean the data
SELECT * 
FROM Portfolio..covid_deaths
WHERE continent is not null
ORDER BY 3,4 ;

SELECT Location  , MAX(cast( total_deaths as int)) as highest_death_cases 
FROM Portfolio..covid_deaths 
WHERE continent is not null
GROUP BY location 
ORDER BY highest_death_cases desc ;

-- showing the continent with the highest death count

SELECT continent  , MAX(cast( total_deaths as int)) as highest_death_cases 
FROM Portfolio..covid_deaths
WHERE continent is not null
GROUP BY continent
ORDER BY highest_death_cases desc ;

-- Global numbers

SELECT   SUM(new_cases)as total_cases , SUM(CAST(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM (New_cases)*100 as Deathpercentage
FROM Portfolio..covid_deaths
WHERE continent is not null
ORDER BY 1, 2 ;


-- Total Population vs vaccination by joining table
SELECT dea.continent , dea.location , dea.date, dea.population , vac.new_vaccinations
FROM Portfolio..covid_deaths dea
JOIN Portfolio..covid_vaccinations  vac
	ON dea.location = vac.location
	and dea.date = vac.date 
WHERE dea.continent is not null
ORDER BY 2,3;

-- Partition by
SELECT dea.continent , dea.location , dea.date, dea.population , vac.new_vaccinations 
, SUM(CONVERT(BIGINT,vac.new_vaccinations )) OVER (Partition by dea.location ORDER BY dea.location , dea.date) 
as rolling_people_vaccinated
FROM Portfolio..covid_deaths dea
JOIN Portfolio..covid_vaccinations  vac
	ON dea.location = vac.location
	and dea.date = vac.date 
WHERE dea.continent is not null
ORDER BY 2,3 ;


-- USE CTE

WITH popvsvac (continent, location , date , population , new_vaccinations ,  rolling_people_vaccinated)
as
(
SELECT dea.continent , dea.location , dea.date, dea.population , vac.new_vaccinations 
, SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (Partition by dea.location ORDER BY dea.location , dea.date) 
as rolling_people_vaccinated
FROM Portfolio..covid_deaths dea
JOIN Portfolio..covid_vaccinations  vac
	ON dea.location = vac.location
	and dea.date = vac.date 
WHERE dea.continent is not null
--ORDER BY 2,3 
)
SELECT * , (rolling_people_vaccinated/population)*100
FROM popvsvac ;


-- TEMP TABLE

DROP TABLE IF exists #percentpopulationvaccinated
CREATE TABLE #percentpopulationvaccinated
(
Continent nvarchar (235),
Location nvarchar (235),
Date datetime ,
Population numeric ,
New_vaccinations numeric ,
rolling_people_vaccinated numeric,
 )


INSERT INTO #percentpopulationvaccinated

SELECT dea.continent , dea.location , dea.date, dea.population , vac.new_vaccinations 
, SUM(CONVERT(BIGINT , vac.new_vaccinations )) OVER (Partition by dea.location ORDER BY dea.location , 
dea.date) as rolling_people_vaccinated
FROM Portfolio..covid_deaths dea
JOIN Portfolio..covid_vaccinations  vac
	ON dea.location = vac.location
	and dea.date = vac.date 
WHERE dea.continent is not null ;

SELECT * ,(rolling_people_vaccinated/population)*100
FROM #percentpopulationvaccinated ;


-- Creating view to store data for later visualization

CREATE VIEW percentpopulationvaccinated AS
SELECT dea.continent , dea.location , dea.date, dea.population , vac.new_vaccinations 
, SUM(CONVERT(BIGINT , vac.new_vaccinations )) OVER (Partition by dea.location ORDER BY dea.location , 
dea.date) as rolling_people_vaccinated
FROM Portfolio..covid_deaths dea
JOIN Portfolio..covid_vaccinations  vac
	ON dea.location = vac.location
	and dea.date = vac.date 
WHERE dea.continent is not null ;

SELECT *
FROM percentpopulationvaccinated ;
