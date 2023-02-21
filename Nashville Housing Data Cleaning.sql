/* 

Cleaning Data in SQL Queries

*/


SELECT *
FROM NashvilleHousingProject.dbo.NashvilleHousing


-- Standarize Sale Date Format (datetime -> date)
SELECT SaleDate, CONVERT(Date,SaleDate)
FROM NashvilleHousingProject.dbo.NashvilleHousing

Update NashvilleHousing
SET SaleDate = CONVERT(Date,SaleDate)

-- Table doesn't update propery, so another method to converting the date format
ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date,SaleDate)


-- Populate Property Address Data
-- some property addresses are missing in the data, but duplicate ParcelIDs have the exact same address
-- so we can use the ParcelID as a reference and fill in the missing ProperyAddress data if available
SELECT *
FROM NashvilleHousingProject.dbo.NashvilleHousing
WHERE PropertyAddress is null
ORDER BY ParcelID

-- write a self-join to compare duplicate ParcelID values from different rows
-- for duplicate ParcelIDs, if Table A PropertyAddress is null, then fill in address data from Table B
SELECT A.ParcelID, A.PropertyAddress, B.ParcelID, B.PropertyAddress, ISNULL(A.PropertyAddress, B.PropertyAddress)
FROM NashvilleHousingProject.dbo.NashvilleHousing AS A
JOIN NashvilleHousingProject.dbo.NashvilleHousing AS B
	ON A.ParcelID = B.ParcelID
	AND A.[UniqueID] <> B.[UniqueID]
WHERE A.PropertyAddress is null

-- Update PropertyAddress column with data from TableB
UPDATE A
SET PropertyAddress = ISNULL(A.PropertyAddress, B.PropertyAddress)
FROM NashvilleHousingProject.dbo.NashvilleHousing AS A
JOIN NashvilleHousingProject.dbo.NashvilleHousing AS B
	ON A.ParcelID = B.ParcelID
	AND A.[UniqueID] <> B.[UniqueID]
WHERE A.PropertyAddress is null



-- Breaking out Address into individual columns (Address and City) using SUBSTRING
SELECT *
FROM NashvilleHousingProject.dbo.NashvilleHousing

-- Finding breakpoint at comma
SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) AS Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+2, LEN(PropertyAddress)) AS City
FROM NashvilleHousingProject.dbo.NashvilleHousing

-- Create new columns for split Address and City
ALTER TABLE NashvilleHousing
ADD PropertySplitAddress nvarchar(255);

ALTER TABLE NashvilleHousing
ADD PropertySplitCity nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+2, LEN(PropertyAddress))


-- Separate Owner Name into FirstName, LastName
SELECT OwnerName
, SUBSTRING(OwnerName, 0, CHARINDEX(',', OwnerName)) AS LastName
, SUBSTRING(OwnerName, CHARINDEX(',', OwnerName)+2, LEN(OwnerName)) AS FirstName
FROM NashvilleHousingProject.dbo.NashvilleHousing


ALTER TABLE NashvilleHousing
ADD FirstName nvarchar(255);

UPDATE NashvilleHousing
SET FirstName = SUBSTRING(OwnerName, CHARINDEX(',', OwnerName)+2, LEN(OwnerName))

ALTER TABLE NashvilleHousing
ADD LastName nvarchar(255);

UPDATE NashvilleHousing
SET LastName = SUBSTRING(OwnerName, 0, CHARINDEX(',', OwnerName))



-- Splitting up OwnerAddress with PARSENAME
SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
, PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)
, PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM NashvilleHousingProject.dbo.NashvilleHousing

-- Create new columns for split Owner Address, City, and State, then update the respective columns
ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress nvarchar(255);

ALTER TABLE NashvilleHousing
ADD OwnerSplitCity nvarchar(255);

ALTER TABLE NashvilleHousing
ADD OwnerSplitState nvarchar(255);


UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

UPDATE NashvilleHousing
SET OwnerSplitCity = TRIM(PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2))

UPDATE NashvilleHousing
SET OwnerSplitState = TRIM(PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1))



-- Change Y and N to Yes and No in 'Sold as Vacant' column
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM NashvilleHousingProject.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

Select SoldAsVacant
, CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
FROM NashvilleHousingProject.dbo.NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant = 
  CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END


-- Remove duplicates
	-- assign row number to the row based on these columns
	-- if all these columns are the exact same, then the row is a duplicate and row_num counter will go up
	-- then use CTE so we can find all rows with row_num > 1
WITH RowNumCTE AS (
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID, 
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY UniqueID
				   ) AS row_num
FROM NashvilleHousingProject.dbo.NashvilleHousing
)
SELECT * -- Should return an empty table after deleting all 104 duplicate rows
--DELETE
FROM RowNumCTE
WHERE row_num > 1


-- Delete unused columns
ALTER TABLE NashvilleHousingProject.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate


