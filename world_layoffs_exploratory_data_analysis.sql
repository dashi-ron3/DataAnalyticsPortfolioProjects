SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
;

SELECT COUNT(total_laid_off)
FROM layoffs_staging2
;

SELECT SUM(total_laid_off)
FROM layoffs_staging2
;

SELECT MIN(date), MAX(date)
FROM layoffs_staging2
;

-- total laid off per industry
SELECT industry, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC -- SUM(total_laid_off)/column 2
;

-- total laid off per country
SELECT country, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY country
ORDER BY 2 DESC
;

-- total laid off per year
SELECT YEAR(date) AS year, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY year
ORDER BY 1 ASC
;

-- total laid off per month of years combined (month 1 of 2020, 2021, 2022 total laid off)
SELECT MONTH(date) AS month, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY month
;

-- total laid off per month and year
SELECT SUBSTRING(`date`,1,7) AS `MONTH`, SUM(total_laid_off)
FROM layoffs_staging2
WHERE SUBSTRING(`date`,1,7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY 1 ASC
;

-- total laid off per year and month
SELECT YEAR(date) AS year, MONTH(date) AS month, SUM(total_laid_off)
FROM layoffs_staging2
WHERE MONTH(date) IS NOT NULL
GROUP BY year, month
ORDER BY 1 ASC
;

SELECT stage, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY stage
ORDER BY 2 DESC 
;

WITH Rolling_Total AS (
	SELECT SUBSTRING(`date`,1,7) AS `MONTH`, SUM(total_laid_off) AS sum_total_laid_off
	FROM layoffs_staging2
	WHERE SUBSTRING(`date`,1,7) IS NOT NULL
	GROUP BY `MONTH`
	ORDER BY 1 ASC
)
SELECT `MONTH`, sum_total_laid_off,
SUM(sum_total_laid_off) OVER(ORDER BY `MONTH`) AS Rolling_Total
FROM Rolling_Total
;

SELECT country, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC
;

SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
ORDER BY 3 DESC
;

WITH Company_Year (company, years, total_laid_off) AS (
	SELECT company, YEAR(`date`), SUM(total_laid_off)
	FROM layoffs_staging2
	GROUP BY company, YEAR(`date`)
), 
Company_Year_Rank AS 
(
	SELECT *, 
	DENSE_RANK() OVER(PARTITION BY years ORDER BY total_laid_off DESC) AS Ranking
	FROM Company_Year
	WHERE years IS NOT NULL
)SELECT *
FROM Company_Year_Rank
WHERE Ranking <= 5
;


