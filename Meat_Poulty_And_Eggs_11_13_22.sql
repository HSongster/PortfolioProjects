-- Importing the FSIS Meat, Poultry, and Egg Inspection Directory updated on 05/14/2022
-- https://catalog.data.gov/dataset/fsis-meat-poultry-and-egg-inspection-directory-by-establishment-name

CREATE TABLE meat_poultry_egg_establishments_new (
    establishment_number text CONSTRAINT est_number_new_key PRIMARY KEY,
    company text,
    street text,
    city text,
    st text,
    zip text,
    phone text,
    grant_date date,
    activities text,
    dbas text
);

COPY meat_poultry_egg_establishments_new
FROM '/Users/hollysongster/Desktop/MPI_Directory_by_Establishment_Number_0.csv'
WITH (FORMAT CSV, HEADER);

CREATE INDEX company_new_idx ON meat_poultry_egg_establishments_new (company);

SELECT *
FROM meat_poultry_egg_establishments_new

-- Count the rows imported:
SELECT count(*) FROM meat_poultry_egg_establishments_new;

-- Finding multiple companies at the same address, it's okay for there to be multiple companies per address
SELECT company,
       street,
       city,
       st,
       count(*) AS address_count
FROM meat_poultry_egg_establishments_new
GROUP BY company, street, city, st
HAVING count(*) > 1
ORDER BY company, street, city, st;

-- Grouping and counting states
SELECT st, 
       count(*) AS st_count
FROM meat_poultry_egg_establishments_new
GROUP BY st
ORDER BY st;

-- Using IS NULL to find missing values in the st column, will need to adjust
-- no values
SELECT establishment_number,
       company,
       city,
       st,
       zip
FROM meat_poultry_egg_establishments_new
WHERE st IS NULL;

-- Using GROUP BY and count() to find inconsistent company names
-- Will need to standardize mispelled names of companies

SELECT company,
       count(*) AS company_count
FROM meat_poultry_egg_establishments_new
GROUP BY company
HAVING count(company)>1
ORDER BY company ASC;

-- Using length() and count() to test the zip column
-- Length (3) = 93, Length(4) = 521, will need to fix

SELECT length(zip),
       count(*) AS length_count
FROM meat_poultry_egg_establishments_new
GROUP BY length(zip)
ORDER BY length(zip) ASC;

-- Filtering with length() to find short zip values
-- Will need to fix inaccurate ZIP codes due to file conversion

SELECT st,
       count(*) AS st_count
FROM meat_poultry_egg_establishments_new
WHERE length(zip) < 5
GROUP BY st
ORDER BY st ASC;

-- Backing up a table

CREATE TABLE meat_poultry_egg_establishments_new_backup AS
SELECT * FROM meat_poultry_egg_establishments_new;

-- Check number of records:
SELECT 
    (SELECT count(*) FROM meat_poultry_egg_establishments_new) AS original,
    (SELECT count(*) FROM meat_poultry_egg_establishments_new_backup) AS backup;

-- Creating and filling the company_standard column

ALTER TABLE meat_poultry_egg_establishments_new ADD COLUMN company_standard text;

UPDATE meat_poultry_egg_establishments_new
SET company_standard = company;

-- Using an UPDATE statement to modify column values that match a string

SELECT company, 
       count(*) AS company_count,
	   street
FROM meat_poultry_egg_establishments_new
GROUP BY company, street
HAVING count(company)>1
ORDER BY company ASC;

SELECT company, street
FROM meat_poultry_egg_establishments_new
WHERE company LIKE 'Americold%'

UPDATE meat_poultry_egg_establishments_new
SET company_standard = 'Americold Logistics LLC'
WHERE company LIKE 'Americold Logistics, LLC'
RETURNING company, company_standard;

-- Creating and filling the zip_copy column

ALTER TABLE meat_poultry_egg_establishments_new ADD COLUMN zip_copy text;

UPDATE meat_poultry_egg_establishments_new
SET zip_copy = zip;

-- Modify codes in the zip column missing two leading zeros

UPDATE meat_poultry_egg_establishments_new
SET zip = '00' || zip
WHERE st IN('PR','VI') AND length(zip) = 3;

-- Modify codes in the zip column missing one leading zero

UPDATE meat_poultry_egg_establishments_new
SET zip = '0' || zip
WHERE st IN('CT','MA','ME','NH','NJ','RI','VT') AND length(zip) = 4;

SELECT length(zip),
       count(*) AS length_count
FROM meat_poultry_egg_establishments_new
GROUP BY length(zip)
ORDER BY length(zip) ASC;

-- Creating and filling a state_regions table

CREATE TABLE state_regions (
    st text CONSTRAINT st_key PRIMARY KEY,
    region text NOT NULL
);

COPY state_regions
FROM '/Users/hollysongster/Desktop/practical-sql-2-main/Chapter_10/state_regions.csv'
WITH (FORMAT CSV, HEADER);

-- Adding and updating an inspection_deadline column

ALTER TABLE meat_poultry_egg_establishments_new
    ADD COLUMN inspection_deadline timestamp with time zone;

UPDATE meat_poultry_egg_establishments_new establishments
SET inspection_deadline = '2022-12-01 00:00 EST'
WHERE EXISTS (SELECT state_regions.region
              FROM state_regions
              WHERE establishments.st = state_regions.st 
                    AND state_regions.region = 'New England');
					
UPDATE meat_poultry_egg_establishments_new establishments
SET inspection_deadline = '2022-12-02 00:00 EST'
WHERE EXISTS (SELECT state_regions.region
              FROM state_regions
              WHERE establishments.st = state_regions.st 
                    AND state_regions.region = 'Mountain');

UPDATE meat_poultry_egg_establishments_new establishments
SET inspection_deadline = '2022-12-03 00:00 EST'
WHERE EXISTS (SELECT state_regions.region
              FROM state_regions
              WHERE establishments.st = state_regions.st 
                    AND state_regions.region = 'Pacific');
					
-- Viewing updated inspection_deadline values

SELECT st, inspection_deadline
FROM meat_poultry_egg_establishments_new
GROUP BY st, inspection_deadline
ORDER BY st;

-- Deleting rows matching an expression

DELETE FROM meat_poultry_egg_establishments_new
WHERE st IN('AS','GU','MP','PR','VI');

-- Removing a column from a table using DROP

ALTER TABLE meat_poultry_egg_establishments_new DROP COLUMN zip_copy;

-- Removing a table from a database using DROP

DROP TABLE meat_poultry_egg_establishments_backup;

-- Demonstrating a transaction block

-- Start transaction and perform update
START TRANSACTION;

UPDATE meat_poultry_egg_establishments_new
SET company = 'AdvancePierre Foods Inc'
WHERE company = 'AdvancePierre Foods, Inc';

-- view changes
SELECT company
FROM meat_poultry_egg_establishments_new
WHERE company LIKE 'AdvancePierre Foods, Inc'
ORDER BY company;

-- Revert changes
ROLLBACK;

-- See restored state
SELECT company
FROM meat_poultry_egg_establishments_new
WHERE company LIKE 'AGRO%'
ORDER BY company;

-- Alternately, commit changes at the end:
START TRANSACTION;

UPDATE meat_poultry_egg_establishments_new
SET company = 'AGRO Merchants Oakland LLC'
WHERE company = 'AGRO Merchants Oakland, LLC';

COMMIT;

-- Backing up a table while adding and filling a new column

CREATE TABLE meat_poultry_egg_establishments_backup AS
SELECT *,
       '2023-02-14 00:00 EST'::timestamp with time zone AS reviewed_date
FROM meat_poultry_egg_establishments_new;

-- Swapping table names using ALTER TABLE

ALTER TABLE meat_poultry_egg_establishments_new 
    RENAME TO meat_poultry_egg_establishments_temp;
ALTER TABLE meat_poultry_egg_establishments_backup 
    RENAME TO meat_poultry_egg_establishments_new;
ALTER TABLE meat_poultry_egg_establishments_temp 
    RENAME TO meat_poultry_egg_establishments_backup;
	
-- Adding Columns to decifer how many plants process meat vs poultry

ALTER TABLE meat_poultry_egg_establishments_new ADD COLUMN meat_processing boolean;
ALTER TABLE meat_poultry_egg_establishments_new ADD COLUMN poultry_processing boolean;
ALTER TABLE meat_poultry_egg_establishments_new ADD COLUMN egg_product boolean;

SELECT * FROM meat_poultry_egg_establishments_new;

UPDATE meat_poultry_egg_establishments_new
SET meat_processing = TRUE
WHERE activities ILIKE '%meat processing%'; -- case-insensitive match with wildcards

UPDATE meat_poultry_egg_establishments_new
SET poultry_processing = TRUE
WHERE activities ILIKE '%poultry processing%'; -- case-insensitive match with wildcards

UPDATE meat_poultry_egg_establishments_new
SET egg_product = TRUE
WHERE activities ILIKE '%egg product'; -- case-insensitive match with wildcards

SELECT * FROM meat_poultry_egg_establishments_new;

-- Count of each type of activity

SELECT count(meat_processing), count(poultry_processing), count(egg_product)
FROM meat_poultry_egg_establishments_new;

-- Count of how many facilities do both activities

SELECT count(*)
FROM meat_poultry_egg_establishments_new
WHERE meat_processing = TRUE AND
      poultry_processing = TRUE AND
	  egg_product = TRUE;