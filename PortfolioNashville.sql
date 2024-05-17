/*
The purpose of this file is to clean data from SQL queries.
*/


SELECT *
FROM PortfolioProject..Nashville


-- This standardize the date format.
SELECT SaleDate, CONVERT(Date,SaleDate) AS ReformattedDate
FROM PortfolioProject..Nashville


-- This adds a new column with the formatted verion 

ALTER TABLE Nashville
ADD ReformattedSaleDate Date NULL;

Update Nashville
SET ReformattedSaleDate = CONVERT(Date,SaleDate);



/*
This section of code populates the property addresses which were left NULL
--------------------------------------------------------------------------
*/

SELECT ParcelID, PropertyAddress
FROM PortfolioProject..Nashville
--WHERE PropertyAddress IS NULL
ORDER BY ParcelID


-- This creates a self join to show different orders; both with the same parcel ID and but one containing a NULL property address.
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM PortfolioProject..Nashville AS a INNER JOIN PORTFOLIOPROJECT..Nashville AS b
	ON a.ParcelID = b.ParcelID AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

-- Now, this updates the table to fill in the NULL PropertyAddress with the address in the matching ParcelID.
Update a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..Nashville a
JOIN PortfolioProject..Nashville b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL



/*
This section focuses on breaking the Address column into 3 individual columns for the Address, City, and State.
---------------------------------------------------------------------------------------------------------------
*/


SELECT PropertyAddress
FROM PortfolioProject..Nashville
--WHERE PropertyAddress IS NULL
--ORDER BY ParcelID

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress)) AS City
From PortfolioProject..Nashville


ALTER TABLE Nashville
ADD PropertySplitAddress Nvarchar(255);

UPDATE Nashville
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 );


ALTER TABLE Nashville
ADD PropertySplitCity Nvarchar(255);

UPDATE Nashville
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress));



-- Now we focus on the Owner Address. This has the address with city and state, so we seperate those into 3 respective columns as well.
-- Note that though Parsename is for FQNs, we manipulate the OwnerAddress so that it can be accepted in the function.
SELECT OwnerAddress
FROM PortfolioProject..Nashville


SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3) AS [Partial Address]
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2) AS City
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1) AS State
FROM PortfolioProject..Nashville


ALTER TABLE Nashville
ADD OwnerPartialAddress Nvarchar(255);

UPDATE Nashville
SET OwnerPartialAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3);


ALTER TABLE Nashville
ADD OwnerCity Nvarchar(255);

UPDATE Nashville
SET OwnerCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2);


ALTER TABLE Nashville
ADD OwnerState Nvarchar(255);

UPDATE Nashville
SET OwnerState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1);





/*
This section changes the rows containing "Y" or "N", and converts them into "Yes"/"No" respectively.
----------------------------------------------------------------------------------------------------
*/

--This checks all distinct values entered in the SoldasVacant column and counts how many of each there are.
SELECT DISTINCT SoldAsVacant, Count(*)
FROM PortfolioProject..Nashville
GROUP BY SoldAsVacant
ORDER BY Count(*);



-- Note this does not update the values; the next block of code will do that.
SELECT SoldAsVacant
, CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
FROM PortfolioProject..Nashville


Update Nashville
SET SoldAsVacant = 
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END




/*
This section removes duplicates rows from the table.
----------------------------------------------------------------------------------------------------
*/

--This views the duplicate rows specifically, using a CTE. 
WITH RowNumCTE AS(
SELECT *, ROW_NUMBER() OVER 
			(PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
			 ORDER BY UniqueID) AS Row_Num
FROM PortfolioProject..Nashville
)
SELECT *
FROM RowNumCTE
WHERE Row_Num > 1
ORDER BY PropertyAddress


-- This deletes the duplicate values.
WITH RowNumCTE AS(
SELECT *, ROW_NUMBER() OVER 
			(PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
			 ORDER BY UniqueID) AS Row_Num
FROM PortfolioProject..Nashville
)
DELETE FROM RowNumCTE
WHERE Row_Num > 1


/*
Delete Unused Columns. Since these columns may be used for some other purpose later on, we will create a new table and insert
values we do want into it.
*/

SELECT *
INTO #Temp
FROM PortfolioProject..Nashville;

ALTER TABLE #Temp
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate

DROP TABLE IF EXISTS PortfolioProject..Nashville_Formatted
SELECT *
INTO PortfolioProject..Nashville_Formatted
FROM #Temp;
DROP TABLE #Temp;

SELECT *
FROM PortfolioProject..Nashville_Formatted;


