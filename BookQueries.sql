/*
The goal here is to prepare the data to be usable for visualization on Tableau.
Data was taken from https://www.kaggle.com/datasets/arashnic/book-recommendation-dataset?select=Users.csv
Though the dataset is meant for book recommendation, we focus on cleaning and organizing data.
Additionally, we also download a list of countries from 
https://github.com/umpirsky/country-list/blob/master/data/en_US/country.csv for later use.
*/

SELECT * FROM dbo.Books ORDER BY Title DESC;

SELECT * FROM dbo.BookRatings;

SELECT * FROM dbo.BookUsers;

/*
Before starting, we clear out unnecessary data and simplify column names.
*/


-- For simplicity, rename columns so they'll be easier to call
EXEC sp_rename 'dbo.Books.[Book-Title]',  'Title', 'COLUMN'; 
EXEC sp_rename 'dbo.Books.[Book-Author]',  'Author', 'COLUMN'; 
EXEC sp_rename 'dbo.Books.[Year-Of-Publication]',  'Published', 'COLUMN'; 

EXEC sp_rename 'dbo.BookRatings.[Book-Rating]',  'Rating', 'COLUMN'; 
EXEC sp_rename 'dbo.BookRatings.[User-ID]',  'ID', 'COLUMN'; 


-- Assume that 0-stars mean they are unrated. So, they are dropped.
DELETE FROM dbo.BookRatings
WHERE BookRatings.Rating = 0;


-- We will not be using the Image-URLs provided, so they are dropped.
ALTER TABLE dbo.Books
DROP COLUMN [Image-URL-S], [Image-URL-M], [Image-URL-L];



/*
This section cleans out duplicate titles and unknown publication dates.
*/


-- First, check for duplicates/re-releases/no publication dates.
SELECT Title, Author, Count(*) AS Amount
FROM dbo.Books
GROUP BY Title, Author
HAVING Count(*) > 1
ORDER BY Title DESC

SELECT Title, Published
FROM dbo.Books
WHERE Published = 0
ORDER BY Title DESC;


WITH RowNumCTE AS(
SELECT *, ROW_NUMBER() OVER 
			(PARTITION BY Title, Author
			 ORDER BY Published) AS Row_Num
FROM PortfolioProject..Books
)
SELECT a.*
FROM RowNumCTE AS a INNER JOIN RowNumCTE AS b ON a.Title = b.Title
WHERE b.Row_Num = 2
ORDER BY Title, Row_Num;


-- Note this checks specifically for duplicate ISBNs, whereas the above partitions to Author.
WITH RowNumCTE AS(
SELECT *, ROW_NUMBER() OVER 
			(PARTITION BY Title, Author, ISBN
			 ORDER BY Published) AS Row_Num
FROM PortfolioProject..Books
)
SELECT a.*
FROM RowNumCTE AS a INNER JOIN RowNumCTE AS b ON a.ISBN = b.ISBN
WHERE b.Row_Num = 2
ORDER BY Published, Title, Row_Num;

-- Now, delete those with no publication/publisher, then those with duplicate ISBNs.
WITH RowNumCTE AS(
SELECT *, ROW_NUMBER() OVER 
			(PARTITION BY Title, Author, ISBN
			 ORDER BY Published) AS Row_Num
FROM PortfolioProject..Books
)
DELETE FROM RowNumCTE
WHERE (Row_Num = 2) OR (Published = 0) OR (Published IS NULL) OR (Publisher IS NULL) OR (Author IS NULL);

-- Note this is for specific cases where a duplicate exists with a different title.
WITH miniCTE AS (
SELECT *, ROW_NUMBER() OVER 
			(PARTITION BY Author, Published, Publisher, ISBN
			 ORDER BY Published) AS Row_Num
FROM PortfolioProject..Books
)
DELETE FROM miniCTE WHERE Row_Num > 1;



/*
This section aggregates and combines the data from both tables.
Afterwards, some formatting is done to prepare it to be sent to Tableau.
*/



-- Summarize the data in the table and combine with data from Books
SELECT ISBN, Count(Rating) AS [Number of Reviews], Round(Avg(Rating), 2) AS [Average Score]
FROM BookRatings
GROUP BY ISBN
ORDER BY [Number of Reviews] DESC


-- Temporary table created to organize all desired data together.
DROP TABLE IF EXISTS #BookRtsStat
CREATE TABLE #BookRtsStat (
ISBN NCHAR(255) NOT NULL PRIMARY KEY,
Title NCHAR(255) NOT NULL,
Author NCHAR(255) NOT NULL,
Published INT NULL,
Publisher NCHAR(255) NOT NULL,
Total_Ratings INT NULL DEFAULT 0,
Average_Rating FLOAT NULL
);

-- This aggregates the BookRatings data to a CTE to be added to the temp table.
WITH Stats_CTE AS (
SELECT ISBN, Count(Rating) AS [Number of Reviews], Round(Avg(Rating), 2) AS [Average Score]
FROM BookRatings
GROUP BY ISBN
)
INSERT INTO #BookRtsStat
SELECT a.*, b.[Number of Reviews], b.[Average Score] FROM Books AS a INNER JOIN Stats_CTE AS b ON a.ISBN = b.ISBN



/*
Now we look at BookUsers. We focus only on State/Country, so we format them seperately.
Note that Location is LOOSELY written in City, State/Province, Country.
For cleaning, we will seperate most into these three columns, but only Country will be used for Tableau.
*/



ALTER TABLE dbo.BookUsers
ADD State NCHAR(255) NULL, 
	Country NCHAR(255) NULL, 
	City NCHAR(255) NULL, 
	temp_loc NCHAR(255) NULL; -- Note this is done to prepare the Location data to be parsed


-- Note that when using PARSENAME, TRIM must be associated here to avoid NULL errors.
-- Clearing " and . characters so the string can be parsed.
UPDATE BookUsers
SET temp_loc =	REPLACE(
			REPLACE(
				REPLACE(Location, '"', ''),
				'.', ''),
			' ', '_'); -- Replacing whitespace with _ allows for the parse function to work even with empty comma spaces.


UPDATE BookUsers
SET State = REPLACE(
		PARSENAME(
			TRIM(
				REPLACE(temp_loc, ',', '.')
				),
			2),
		'_', ''),
	Country = SUBSTRING(
			Location,
			4+LEN(Location)-CHARINDEX(',', REVERSE(Location)),
			LEN(temp_loc)
			),
	City = SUBSTRING(temp_loc, 0, 
			CHARINDEX(',', temp_loc));

-- Those with no data for country will be converted to NULL values, and the rest capitalized.
UPDATE BookUsers
SET Country = NULL
WHERE Country = 'n/a' OR LEN(Country) = 0;
UPDATE BookUsers
SET Country = UPPER(LEFT(Country,1)) + SUBSTRING(Country, 2, len(Country))
WHERE COUNTRY IS NOT NULL;



/*
Unfortunately, many entered values for Country are either mispelled or not written with the correct format.
We use Soundex() and a table of countries to try to solve this issue.
*/



-- This compares the Country values from BookUsers and sees if it matches with the listings in the CountryList
WITH ACompCTE AS (
SELECT a.Country, b.id, b.value FROM BookUsers AS a INNER JOIN CountryList AS b ON a.Country = b.id
)
UPDATE ACompCTE
SET Country = id;

WITH ACompCTE AS (
SELECT a.Country, b.id, b.value FROM BookUsers AS a INNER JOIN CountryList AS b ON a.Country = b.value
)
UPDATE ACompCTE
SET Country = value;

-- This uses Soundex function to approximate the rest.
-- NOTE! Soundex is not perfect, and many approximations are not fully accurate.
-- However, this does take care of most cases and allows for Tableau to not have to choose between similar values for one country.

-- We add a soundex column for compatibility to both tables.
ALTER TABLE CountryList
ADD SoundValue VARCHAR(5) NULL;
UPDATE CountryList
SET SoundValue = SOUNDEX(value);

ALTER TABLE BookUsers
ADD Sound_Value VARCHAR(5) NULL;
UPDATE BookUsers
SET Sound_Value = Soundex(Country);

WITH ACompCTE AS (
SELECT a.Country, b.value FROM BookUsers AS a INNER JOIN CountryList AS b ON a.Sound_Value = b.SoundValue 
)
UPDATE ACompCTE
SET Country = value
WHERE (NOT EXISTS (SELECT * FROM CountryList WHERE ACompCTE.Country = value OR ACompCTE.Country = id)) AND Country IS NOT NULL
;

-- Below checks for any remaining values in BookUsers which did not find a match.
SELECT Country, Count(*) FROM BookUsers AS A
WHERE NOT EXISTS (SELECT value FROM BookUsers INNER JOIN CountryList ON Sound_Value = SoundValue 
					WHERE A.Country = value)
GROUP BY Country
ORDER BY Count(*) DESC;

-- Since Usa is the most prominent one, we make a special correction for them.
UPDATE BookUsers
SET Country = 'United States'
WHERE Country = 'Usa';

-- Finally, we set all remaining Country values which did not find a matching country to NULL. 
UPDATE BookUsers
SET Country = NULL
WHERE NOT EXISTS (SELECT value FROM BookUsers AS A INNER JOIN CountryList ON Sound_Value = SoundValue 
			WHERE BookUsers.Country = value)
	AND NOT EXISTS (SELECT id FROM BookUsers AS A INNER JOIN CountryList ON BookUsers.Country = id
			WHERE BookUsers.Country = id)
	AND Country IS NOT NULL;



/*
Now we move on to preparing queries to take to Tableau.
*/


SELECT * FROM #BookRtsStat;

SELECT [User-ID], Age, Country FROM BookUsers;

-- This finds the 5 most popular books, and lists all the ages of those who rated them. 
WITH PieCTE AS (
SELECT TOP(5) Title, ISBN FROM #BookRtsStat ORDER BY Total_Ratings DESC
)
SELECT Title, Age, ID, Country FROM PieCTE INNER JOIN BookRatings ON PieCTE.ISBN = BookRatings.ISBN
					 INNER JOIN BookUsers ON BookRatings.ID = BookUsers.[User-ID]
WHERE Age IS NOT NULL AND Age >= 5 AND Age < 100
ORDER BY Title, Age



