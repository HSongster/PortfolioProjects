/*
Cleaning Data in SQL Queries
*/

SELECT *
FROM nashville_housing_data_1;
----------------------------------
--Populate Property Address: Replacing null values on Propertyaddress where address can 
--be found elsewhere in same table


SELECT *
FROM nashville_housing_data_1
--WHERE propertyaddress is null
ORDER BY parcelid;

SELECT a.parcelid, a.propertyaddress, b.parcelid, b.propertyaddress, 
COALESCE(b.propertyaddress, a.propertyaddress)
FROM nashville_housing_data_1 a
JOIN nashville_housing_data_1 b
	ON a.parcelid = b.parcelid
	AND a.uniqueid <> b.uniqueid
WHERE a.propertyaddress is NULL;

UPDATE nashville_housing_data_1 AS a
SET PropertyAddress = COALESCE(b.propertyaddress, a.propertyaddress)
FROM nashville_housing_data_1 AS b 
WHERE a.parcelid = b.parcelid 
AND a.uniqueid <> b.uniqueid 
AND a.propertyaddress IS NULL;


------------------------------------------
-- Breaking out Address into Individual Columns (Address, City, State)

SELECT PropertyAddress
FROM nashville_housing_data_1;
--Where PropertyAddress is null
--order by ParcelID

SELECT
SPLIT_PART(propertyaddress, ',', 1) as Address,
SPLIT_PART(propertyaddress, ',', -1) as City
FROM nashville_housing_data_1;

ALTER TABLE nashville_housing_data_1
ADD PropertySplitAddress varchar (255);

UPDATE nashville_housing_data_1
SET PropertySplitAddress = SPLIT_PART(propertyaddress, ',', 1);

ALTER TABLE nashville_housing_data_1
ADD PropertySplitCity varchar (255);

UPDATE nashville_housing_data_1
SET PropertySplitCity = SPLIT_PART(propertyaddress, ',', -1);

----
SELECT OwnerAddress
FROM nashville_housing_data_1;

SELECT
SPLIT_PART(owneraddress, ',', 1),
SPLIT_PART(owneraddress, ',', 2),
SPLIT_PART(owneraddress, ',', -1)
From nashville_housing_data_1;

ALTER TABLE nashville_housing_data_1
ADD OwnerSplitAddress varchar(255),
	OwnerSplitCity varchar(255),
 	OwnerSplitState varchar(255);

UPDATE nashville_housing_data_1
SET OwnerSplitAddress = SPLIT_PART(owneraddress, ',', 1),
	OwnerSplitCity = SPLIT_PART(owneraddress, ',', 2),
	OwnerSplitState = SPLIT_PART(owneraddress, ',', -1);

Select *
FROM nashville_housing_data_1
ORDER BY parcelid;

--------------------------------------
-- Change 'Y' and 'N' to 'Yes' and 'No' in "Sold as Vacant" field

SELECT Distinct(SoldAsVacant), Count(SoldAsVacant)
FROM nashville_housing_data_1
GROUP BY SoldAsVacant
ORDER BY 2;

SELECT SoldAsVacant
, CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
FROM nashville_housing_data_1;

UPDATE nashville_housing_data_1
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END;

--------------------------------------
-- Remove Duplicates

WITH cte 
AS 
(
SELECT ctid,
	ROW_NUMBER() OVER(PARTITION BY 
		ParcelID,
		PropertyAddress,
             	SalePrice,
             	SaleDate,
             	LegalReference
             	ORDER BY UniqueID) AS row_num
FROM nashville_housing_data_1
)
DELETE FROM 
	nashville_housing_data_1
	USING cte
	WHERE row_num >1	
	AND cte.ctid = nashville_housing_data_1.ctid;


SELECT *
FROM nashville_housing_data_1;

----------------------------------
-- Delete Unused Columns

Select *
From nashville_housing_data_1;

ALTER TABLE nashville_housing_data_1
--DROP COLUMN OwnerAddress, 
DROP COLUMN Propertyaddress;


