- SQL Project - Data Cleaning

-- https://www.kaggle.com/datasets/swaptr/layoffs-2022






SELECT * 
FROM world_layoffs.layoffs;



-- first thing we want to do is create a staging table. This is the one we will work in and clean the data. We want a table with the raw data in case something happens
CREATE TABLE world_layoffs.layoffs_staging 
LIKE world_layoffs.layoffs;

INSERT layoffs_staging 
SELECT * FROM world_layoffs.layoffs;


-- now when we are data cleaning we usually follow a few steps
-- 1. check for duplicates and remove any
-- 2. standardize data and fix errors
-- 3. Look at null values and see what 
-- 4. remove any columns and rows that are not necessary - few ways



-- 1. Remove Duplicates

# First let's check for duplicates



SELECT *
FROM world_layoffs.layoffs_staging
;

SELECT company, industry, total_laid_off,`date`,
		ROW_NUMBER() OVER (
			PARTITION BY company, industry, total_laid_off,`date`) AS row_num
	FROM 
		world_layoffs.layoffs_staging;



SELECT *
FROM (
	SELECT company, industry, total_laid_off,`date`,
		ROW_NUMBER() OVER (
			PARTITION BY company, industry, total_laid_off,`date`
			) AS row_num
	FROM 
		world_layoffs.layoffs_staging
) duplicates
WHERE 
	row_num > 1;
    
-- let's just look at oda to confirm
SELECT *
FROM world_layoffs.layoffs_staging
WHERE company = 'Oda'
;
-- it looks like these are all legitimate entries and shouldn't be deleted. We need to really look at every single row to be accurate

-- these are our real duplicates 
SELECT *
FROM (
	SELECT company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions,
		ROW_NUMBER() OVER (
			PARTITION BY company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions
			) AS row_num
	FROM 
		world_layoffs.layoffs_staging
) duplicates
WHERE 
	row_num > 1;

-- these are the ones we want to delete where the row number is > 1 or 2or greater essentially

-- now you may want to write it like this:
WITH DELETE_CTE AS 
(
SELECT *
FROM (
	SELECT company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions,
		ROW_NUMBER() OVER (
			PARTITION BY company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions
			) AS row_num
	FROM 
		world_layoffs.layoffs_staging
) duplicates
WHERE 
	row_num > 1
)
DELETE
FROM DELETE_CTE
;


WITH DELETE_CTE AS (
	SELECT company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions, 
    ROW_NUMBER() OVER (PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
	FROM world_layoffs.layoffs_staging
)
DELETE FROM world_layoffs.layoffs_staging
WHERE (company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions, row_num) IN (
	SELECT company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions, row_num
	FROM DELETE_CTE
) AND row_num > 1;

-- one solution, which I think is a good one. Is to create a new column and add those row numbers in. Then delete where row numbers are over 2, then delete that column
-- so let's do it!!

ALTER TABLE world_layoffs.layoffs_staging ADD row_num INT;


SELECT *
FROM world_layoffs.layoffs_staging
;

CREATE TABLE `world_layoffs`.`layoffs_staging2` (
`company` text,
`location`text,
`industry`text,
`total_laid_off` INT,
`percentage_laid_off` text,
`date` text,
`stage`text,
`country` text,
`funds_raised_millions` int,
row_num INT
);

INSERT INTO `world_layoffs`.`layoffs_staging2`
(`company`,
`location`,
`industry`,
`total_laid_off`,
`percentage_laid_off`,
`date`,
`stage`,
`country`,
`funds_raised_millions`,
`row_num`)
SELECT `company`,
`location`,
`industry`,
`total_laid_off`,
`percentage_laid_off`,
`date`,
`stage`,
`country`,
`funds_raised_millions`,
		ROW_NUMBER() OVER (
			PARTITION BY company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions
			) AS row_num
	FROM 
		world_layoffs.layoffs_staging;

-- now that we have this we can delete rows were row_num is greater than 2


SET SQL_SAFE_UPDATES = 0;



DELETE FROM layoffs_staging2
WHERE row_num >1 ;


SELECT * 
FROM layoffs_staging2
where row_num>1;

select * 
from layoffs_staging2

;


-- 2. Standardize Data

select company,trim(company)
from layoffs_staging2;


update layoffs_staging2
set company=trim(company);

select distinct(industry)
from layoffs_staging2
order by 1;


select *
from layoffs_staging2
where industry like 'Crypto%';


update layoffs_staging2
set industry ='Crypto'
where industry like 'Crypto%';

select distinct(country)
from layoffs_staging2
order by 1
;

update layoffs_staging2
set industry ='Crypto'
where industry like 'Crypto%';



select distinct country , trim(trailing '.' from country)
from layoffs_staging2
order by 1;

update layoffs_staging2
set country =trim(trailing '.' from country)
where country like 'United States%';


select `date`,
str_to_date(`date`,'%m/%d/%Y')
from layoffs_staging2;

select `date`
from layoffs_staging2;


update layoffs_staging2
set `date` =str_to_date(`date`,'%m/%d/%Y');


alter table layoffs_staging2
modify column `date` DATE;



select *
from layoffs_staging2
where total_laid_off is null
and percentage_laid_off is null;


select distinct *
from  layoffs_staging2
where  industry is null 
or industry  =''
;


select distinct *
from layoffs_staging2
where company =  'Airbnb';


select  t1.industry ,t2.industry
from layoffs_staging2 t1
join layoffs_staging2 t2
on t1.company=t2.company
where (  t1.industry is null  or t1.industry='')
and  t2.industry is not null ;



update  layoffs_staging2 t1
join layoffs_staging2 t2
on t1.company =t2.company
set t1.industry=t2.industry
where (  t1.industry is null  )
and  t2.industry is not null ;

update layoffs_staging2
set industry =null
where industry ='';


select *
from layoffs_staging2
where company   like 'Bally%';


select  *
from layoffs_staging2;

delete
from layoffs_staging2
where total_laid_off is null
and percentage_laid_off is null;


alter table layoffs_staging2
drop column row_num;




SELECT company, location, industry, total_laid_off, COUNT(*) AS cnt
FROM layoffs_staging2
GROUP BY company, location, industry, total_laid_off
HAVING COUNT(*) > 1;


ALTER TABLE layoffs_staging2 ADD COLUMN row_num INT;

SELECT 
  company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions,
  COUNT(*) AS cnt
FROM layoffs_staging2
GROUP BY 
  company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions
HAVING COUNT(*) > 1;


DELETE FROM layoffs_staging2
WHERE (company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) IN (
    SELECT company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions
    FROM layoffs_staging2
    GROUP BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions
    HAVING COUNT(*) > 1
)
AND id NOT IN (
    SELECT MIN(id)
    FROM layoffs_staging2
    GROUP BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions
);



ALTER TABLE layoffs_staging2 ADD COLUMN row_num INT;

CREATE TEMPORARY TABLE layoffs_with_rn AS
SELECT *,
       ROW_NUMBER() OVER (
         PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions
         ORDER BY company
       ) AS rn
FROM layoffs_staging2;




UPDATE layoffs_staging2 t1
JOIN layoffs_with_rn t2
ON t1.company = t2.company
AND t1.location = t2.location
AND t1.industry = t2.industry
AND t1.total_laid_off = t2.total_laid_off
AND t1.percentage_laid_off = t2.percentage_laid_off
AND t1.`date` = t2.`date`
AND t1.stage = t2.stage
AND t1.country = t2.country
AND t1.funds_raised_millions = t2.funds_raised_millions
SET t1.row_num = t2.rn;

SELECT * FROM layoffs_staging2 WHERE row_num > 1;


DELETE FROM layoffs_staging2
WHERE row_num > 1;

ALTER TABLE layoffs_staging2 DROP COLUMN row_num;

