-- -- --  -- AUTOMATED DATA CLEANING PROJECT -- -- -- -- 
-- original data set
SELECT * 
FROM bakery.ushouseholdincome;

-- cleaned data set
SELECT * 
FROM bakery.us_household_income_cleaned;

-- STEP 1: CREATE THE PROCEDURE -- 

DELIMITER $$
DROP PROCEDURE IF EXISTS Copy_and_Clean_Data;
CREATE PROCEDURE Copy_and_Clean_Data()
BEGIN

-- creating our table (copy statement from the original data set)
	CREATE TABLE IF NOT EXISTS `us_household_income_cleaned` (
	  `row_id` int DEFAULT NULL,
	  `id` int DEFAULT NULL,
	  `State_Code` int DEFAULT NULL,
	  `State_Name` text,
	  `State_ab` text,
	  `County` text,
	  `City` text,
	  `Place` text,
	  `Type` text,
	  `Primary` text,
	  `Zip_Code` int DEFAULT NULL,
	  `Area_Code` int DEFAULT NULL,
	  `ALand` int DEFAULT NULL,
	  `AWater` int DEFAULT NULL,
	  `Lat` double DEFAULT NULL,
	  `Lon` double DEFAULT NULL,
	  `TimeStamp` TIMESTAMP DEFAULT NULL -- add this because we are creating an automated process. We need this timestamp so we can go back and look, debug and find the issue.
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
    
-- Copy data to new table
	INSERT INTO us_household_income_cleaned
    SELECT *, current_timestamp()
	FROM bakery.ushouseholdincome;

-- Data Cleaning Steps
	-- 1. Remove Duplicates
	DELETE FROM us_household_income_cleaned
	WHERE 
		row_id IN (
		SELECT row_id
	FROM (
		SELECT row_id, id,
			ROW_NUMBER() OVER (
				PARTITION BY id, `TimeStamp` -- we include the timestamp. The timestamp is unique each time it runs. So we won't be removing duplicates for all the data, but only for the timestamp.
				ORDER BY id,`TimeStamp`) AS row_num
		FROM 
			us_household_income_cleaned
	) duplicates
	WHERE 
		row_num > 1
	);

	-- 2. Fixing some data quality issues by fixing typos and general standardization
	UPDATE us_household_income_cleaned
	SET State_Name = 'Georgia'
	WHERE State_Name = 'georia';

	UPDATE us_household_income_cleaned
	SET County = UPPER(County);

	UPDATE us_household_income_cleaned
	SET City = UPPER(City);

	UPDATE us_household_income_cleaned
	SET Place = UPPER(Place);

	UPDATE us_household_income_cleaned
	SET State_Name = UPPER(State_Name);

	UPDATE us_household_income_cleaned
	SET `Type` = 'CDP'
	WHERE `Type` = 'CPD';

	UPDATE us_household_income_cleaned
	SET `Type` = 'Borough'
	WHERE `Type` = 'Boroughs';
    
END $$
DELIMITER ;

CALL Copy_and_Clean_Data();

-- Debugging or checking store procedure works

		SELECT row_id, id, row_num
		FROM (
			SELECT row_id, id,
				ROW_NUMBER() OVER (
				PARTITION BY id
				ORDER BY id) AS row_num
			FROM 
				us_household_income_cleaned
			) duplicates
		WHERE 
			row_num > 1;
    
SELECT count(row_id)
FROM us_household_income_cleaned;

SELECT state_name, count(state_name)
FROM us_household_income_cleaned
GROUP BY state_name;

-- STEP 2: CREATE THE EVENT --
DROP EVENT run_data_cleaning;
CREATE EVENT run_data_cleaning
	ON SCHEDULE EVERY 30 DAY -- use 1 MINUTEfor checking purposes
    DO CALL Copy_and_Clean_Data();

-- to check if the event is working or running 
SELECT DISTINCT TimeStamp
FROM bakery.us_household_income_cleaned;

-- END.

