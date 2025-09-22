-- DATA CLEANING SQL PROJECT

SELECT *
FROM layoffs;

-- 1. Remove Duplicates
-- 2. Standardize the Data
-- 3. Null Values or Blank Values
-- 4. Remove Unecessary Columns or Rows

-- NEVER EDIT THE RAW DATASET/RAW DATA

-- REMOVING DUPLICATES
-- create another table to edit (NEVER EDIT THE RAW DATASET)
CREATE TABLE layoffs_staging
LIKE layoffs; # gets all columns from layoffs 

-- inserting all values from layoffs to layoffs_staging
INSERT layoffs_staging
SELECT * 
FROM layoffs;

-- remove all duplicates (no id column scenario so gonna be a bit hard)
# getting values with duplicates
WITH duplicate_cte AS
(
	SELECT *,
	ROW_NUMBER() OVER(PARTITION BY company, location, 
    industry, total_laid_off, percentage_laid_off, `date`, 
    stage, country, funds_raised_millions) AS row_num 
	#using back-ticks so as to not confuse it with the date keyword in sql
	FROM layoffs_staging
)
SELECT *
FROM duplicate_cte 
WHERE row_num > 1;

# to check if one of the results actually has duplicates
SELECT *
FROM layoffs_staging
WHERE company = 'Casper';

# create a new table and add row_num column
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT *
FROM layoffs_staging2;

INSERT INTO layoffs_staging2
SELECT *,
	ROW_NUMBER() OVER(PARTITION BY company, location, 
    industry, total_laid_off, percentage_laid_off, `date`, 
    stage, country, funds_raised_millions) AS row_num 
	#using back-ticks so as to not confuse it with the date keyword in sql
	FROM layoffs_staging;

# just to check
SELECT * 
FROM layoffs_staging2
WHERE row_num > 1;

# deletes all duplicates
DELETE 
FROM layoffs_staging2
WHERE row_num > 1;

SELECT *
FROM layoffs_staging2;


-- STANDARDIZING DATA --
SELECT company, TRIM(company)
FROM layoffs_staging2;

# updates company column
UPDATE layoffs_staging2
SET company = TRIM(company);

SELECT DISTINCT industry
FROM layoffs_staging2;

# updating values like Crypto Currency into the majority Crypto
SELECT * 
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

# just checking if other columns have issues
SELECT DISTINCT location
FROM layoffs_staging2
ORDER BY location;

SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY country;

SELECT *
FROM layoffs_staging2
WHERE country LIKE 'United States%';

# removing the period from United States.
SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY country;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

# date is saved as text so we need to change it
SELECT `date`,
STR_TO_DATE(`date`, '%m/%d/%Y') # use small case m,d and capital Y
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y'); # in the schemas, date is still saved as text in layoffs_staging2

# this changes it to the date format inside the schema
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;


-- NULL OR BLANK VALUES -- 
SELECT * 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = ''; # means blank

# replace blank with NULL so we can populate it
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

SELECT * 
FROM layoffs_staging2
WHERE company = 'Airbnb'; #1 has blank industry, one has not. It can be populated with the none NULL so we will populate the one with missing values.
# as for 'Bally', there is no NONE NULL row with same company so we cannot populate as we don't know what insdustry they are in

SELECT t1.industry, t2.industry
FROM layoffs_staging2 AS t1
JOIN layoffs_staging2 AS t2
	ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NUll;

# remove OR since we replaced all blanks ('') with NULL values
SELECT t1.industry, t2.industry
FROM layoffs_staging2 AS t1
JOIN layoffs_staging2 AS t2
	ON t1.company = t2.company
WHERE t1.industry IS NULL
AND t2.industry IS NOT NUll;

# updating to populate those with NULL values
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NUll;


-- in the case of the total laid off, I don't think we can populate since 
-- we have no idea of the total num of employees they have (ex. total_emp column) --
-- 1 percent (in this table) means all employees we're laid off (company went under)
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

# deleting since unsure if they actually laid off emps as both total_laid_off and per_laid_off is NULL
# we can't get how many were laid off and calculate the percentage
DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT * 
FROM layoffs_staging2;


-- REMOVING UNNECESSARY COLUMNS OR ROWS
#getting rid of row_num column since we don't need it anymore
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

#YAYYY CLEANING IS DONE
SELECT *
FROM layoffs_staging2;