
-- 1. Remove Duplicates
-- 2. Standardize the Data
-- 3. Null Values or Blank Values
-- 4. Remove Unecessary Columns or Rows

---------------------------------------------------------------------------------------------------------------
-- REMOVING DUPLICATES
CREATE TABLE layoffs_staging
LIKE layoffs; # gets all columns from layoffs 

INSERT layoffs_staging
SELECT * 
FROM layoffs;

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


-- to check if one of the results actually has duplicates
SELECT *
FROM layoffs_staging
WHERE company = 'Casper';

-- create a new table and add row_num column
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

-- deletes all duplicates
DELETE 
FROM layoffs_staging2
WHERE row_num > 1;

SELECT *
FROM layoffs_staging2;



---------------------------------------------------------------------------------------------------------------
-- STANDARDIZING DATA --
SELECT company, TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);

-- updating 'Crypto Currency to Crypto for uniformity
SELECT DISTINCT industry
FROM layoffs_staging2;


SELECT * 
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';


SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY country;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';


-- changing date column from text to date type
SELECT `date`,
STR_TO_DATE(`date`, '%m/%d/%Y') # use small case m,d and capital Y
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y'); # in the schemas, date is still saved as text in layoffs_staging2

# this changes it to the date format inside the schema
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;



---------------------------------------------------------------------------------------------------------------
-- REMOVING NULL OR BLANK VALUES -- 
SELECT * 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;


SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = '';
	
-- replace blank with NULL
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';


SELECT t1.industry, t2.industry
FROM layoffs_staging2 AS t1
JOIN layoffs_staging2 AS t2
	ON t1.company = t2.company
WHERE t1.industry IS NULL
AND t2.industry IS NOT NUll;

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NUll;


SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;



---------------------------------------------------------------------------------------------------------------
-- REMOVING UNNECESSARY COLUMNS OR ROWS
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

SELECT *
FROM layoffs_staging2;
