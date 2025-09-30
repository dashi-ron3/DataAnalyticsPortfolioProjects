
CREATE TABLE customers_staging
LIKE customers
; --gets all columns from customers

INSERT customers_staging
SELECT *
FROM customers
; --inserting all data from customers

SELECT *
FROM customers_staging;


-- Removed leading/trailing spaces and format name to Proper case
UPDATE customers_staging
SET
    first_name = CONCAT(
        UPPER(LEFT(TRIM(first_name), 1)),
        LOWER(SUBSTRING(TRIM(first_name), 2))
    ),

    last_name = CONCAT(
            UPPER(LEFT(TRIM(last_name), 1)),
            LOWER(SUBSTRING(TRIM(last_name), 2))
        ),

    email = LOWER(TRIM(email)
);


-- cleaning and formatting phone numbers
SELECT * 
FROM customers_staging
WHERE phone = '';

UPDATE customers_staging
SET phone = NULL
WHERE phone = '';

SELECT phone, 
RIGHT(REGEXP_REPLACE(phone, '[^0-9]', ''), 10)
FROM customers_staging
;

UPDATE customers_staging
SET phone = RIGHT(REGEXP_REPLACE(phone, '[^0-9]', ''), 10)
WHERE phone IS NOT NULL;

-- turn phone numbers into standard XXX-XXX-XXXX format
UPDATE customers_staging
SET phone = CASE
    WHEN LENGTH(phone) = 11 AND LEFT(phone, 1) = '1' THEN
        CONCAT(
            SUBSTRING(phone, 2, 3), '-',   
            SUBSTRING(phone, 5, 3), '-',   
            SUBSTRING(phone, 8, 4)         
        )
    WHEN LENGTH(phone) = 10 THEN
        CONCAT(
            SUBSTRING(phone, 1, 3), '-',
            SUBSTRING(phone, 4, 3), '-',
            SUBSTRING(phone, 7, 4)
        )
    ELSE phone 
END;

-- cleaning email entries 
UPDATE customers_staging
SET email = REPLACE(email, ',com', '.com')
WHERE email LIKE '%,com';

UPDATE customers_staging
SET email = CONCAT(email, '.com')
WHERE email NOT LIKE '%.com' AND email LIKE '%@gmail';

SELECT id, email
FROM customers_staging
WHERE email LIKE '%@@%';

UPDATE customers_staging 
SET email = REPLACE(email, '@@', '@')
WHERE email LIKE '%@@%';

-- Populated customer with empty last_name using their email
SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(email, '@', 1), '.', -1) AS last_name_guess
FROM customers_staging
WHERE first_name = 'Mary';

UPDATE customers_staging
SET last_name = CONCAT(
        UPPER(LEFT(SUBSTRING_INDEX(SUBSTRING_INDEX(email, '@', 1), '.', -1), 1)),
        LOWER(SUBSTRING(SUBSTRING_INDEX(SUBSTRING_INDEX(email, '@', 1), '.', -1), 2))
    )
WHERE last_name IS NULL
  AND first_name = SUBSTRING_INDEX(SUBSTRING_INDEX(email, '@', 1), '.', 1);


-- cleaning and turning date into standard format
ALTER TABLE customers_staging ADD COLUMN signup_date_clean DATE;

UPDATE customers_staging
SET signup_date_clean =
    CASE
        WHEN signup_date REGEXP '^[0-9]{4}/[0-9]{2}/[0-9]{2}$' 
            THEN STR_TO_DATE(signup_date, '%Y/%m/%d')
        WHEN signup_date REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' 
            THEN STR_TO_DATE(signup_date, '%d-%m-%Y')
        WHEN signup_date REGEXP '^[0-9]{8}$' 
            THEN STR_TO_DATE(signup_date, '%Y%m%d')
        WHEN signup_date REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' 
            THEN STR_TO_DATE(signup_date, '%m/%d/%Y')
        WHEN signup_date REGEXP '^[0-9]{2} [A-Za-z]+ [0-9]{4}$' 
            THEN STR_TO_DATE(signup_date, '%d %M %Y')
		WHEN signup_date REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
			THEN STR_TO_DATE(signup_date, '%Y-%m-%d')
		WHEN signup_date REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{2}$'
			THEN STR_TO_DATE(signup_date, '%m-%d-%Y')
		WHEN signup_date REGEXP '^[0-9]{4}.[0-9]{2}.[0-9]{2}$'
			THEN STR_TO_DATE(signup_date, '%Y.%m.%d')
		WHEN signup_date REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{2}$' 
            THEN STR_TO_DATE(signup_date, '%m/%d/%Y')
        ELSE NULL
    END;


-- Removing duplicate entries
WITH ranked AS (
    SELECT 
        id,
        first_name,
        last_name,
        email,
        phone,
        city,
        signup_date_clean,
        ROW_NUMBER() OVER (
            PARTITION BY first_name, last_name, signup_date_clean,
            LOWER(TRIM(first_name)), LOWER(TRIM(last_name))
            ORDER BY signup_date_clean DESC
        ) AS rn
    FROM customers_staging
)
DELETE 
FROM customers_staging
WHERE id IN (SELECT id FROM ranked WHERE rn > 1);

SELECT * FROM customers_staging;


-- create a table with the cleaned data
CREATE TABLE customers_clean AS
SELECT 
    id,
    first_name,
    last_name,
    email,
    phone,
    city,
    signup_date_clean AS signup_date
FROM customers_staging;

SELECT * 
FROM customers_clean;

  

