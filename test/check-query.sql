---------------------------------------------------------
------------------- CRM_CUST_INFO CHECKS ----------------
---------------------------------------------------------

-- Check for duplicated cst_id
SELECT cst_id, COUNT(*)
FROM [bronze].[crm_cust_info]
GROUP BY cst_id
HAVING COUNT(*) > 1

-- Check for extra spaces in cst_firstname
SELECT [cst_firstname]
FROM [bronze].[crm_cust_info]
WHERE [cst_firstname] != TRIM([cst_firstname])

-- Check for extra spaces in cst_lastname
SELECT [cst_lastname]
FROM [bronze].[crm_cust_info]
WHERE [cst_lastname] != TRIM([cst_lastname])

-- Check for extra spaces in gender column
SELECT [cst_gndr]
FROM [bronze].[crm_cust_info]
WHERE [cst_gndr] != TRIM([cst_gndr])

-- Distinct gender values
SELECT DISTINCT [cst_gndr]
FROM [bronze].[crm_cust_info]

-- Distinct marital status
SELECT DISTINCT [cst_marital_status]
FROM [bronze].[crm_cust_info]

---------------------------------------------------------
------------------- CRM_PRD_INFO CHECKS -----------------
---------------------------------------------------------

-- Raw data check
SELECT * FROM [bronze].[crm_prd_info]

-- Check for duplicated or null prd_id
SELECT prd_id, COUNT(*)
FROM [bronze].[crm_prd_info]
GROUP BY prd_id
HAVING COUNT(*) > 1 AND prd_id IS NULL

-- Count distinct vs total prd_id
SELECT COUNT(DISTINCT prd_id) AS dis FROM [bronze].[crm_prd_info]
SELECT COUNT(prd_id) AS dis FROM [bronze].[crm_prd_info]

-- Extract and transform prd_key
SELECT 
  prd_id,
  prd_key,
  REPLACE(SUBSTRING(prd_key,1,5),'-','_') AS cat_id,
  SUBSTRING(prd_key,7,LEN(prd_key)) AS prd_key,
  prd_nm,
  prd_cost,
  prd_line,
  prd_start_dt,
  prd_end_dt
FROM [bronze].[crm_prd_info]

-- Validate cat_id join with erp_PX_CAT_G1V2
SELECT *
FROM [bronze].[crm_prd_info]
WHERE REPLACE(SUBSTRING(prd_key,1,5),'-','_') NOT IN (
  SELECT DISTINCT [ID] FROM [bronze].[erp_PX_CAT_G1V2]
)

-- Validate prd_key join with crm_sales_details
SELECT *
FROM [bronze].[crm_prd_info]
WHERE SUBSTRING(prd_key,7,LEN(prd_key)) NOT IN (
  SELECT [sls_prd_key] FROM [bronze].[crm_sales_details]
)

-- Check for extra spaces in prd_nm
SELECT [prd_nm]
FROM [bronze].[crm_prd_info]
WHERE [prd_nm] != TRIM([prd_nm])

-- Check for negative or null prd_cost
SELECT [prd_cost]
FROM [bronze].[crm_prd_info]
WHERE prd_cost < 0 OR prd_cost IS NULL

-- Distinct prd_line for standardization
SELECT DISTINCT [prd_line]
FROM [bronze].[crm_prd_info]

-- Date quality check
SELECT [prd_start_dt], [prd_end_dt]
FROM [bronze].[crm_prd_info]
WHERE [prd_start_dt] > [prd_end_dt]

---------------------------------------------------------
------------------- SILVER CRM_PRD_INFO -----------------
---------------------------------------------------------

-- Check duplicated or null prd_id
SELECT prd_id, COUNT(*)
FROM [silver].[crm_prd_info]
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL

-- Trim check for prd_nm
SELECT [prd_nm]
FROM [silver].[crm_prd_info]
WHERE [prd_nm] != TRIM([prd_nm])

-- Check for invalid prd_cost
SELECT [prd_cost]
FROM [silver].[crm_prd_info]
WHERE prd_cost < 0 OR prd_cost IS NULL

---------------------------------------------------------
------------------- CRM_SALES_DETAILS -------------------
---------------------------------------------------------

-- Check duplicated or null sls_ord_num
SELECT [sls_ord_num], COUNT(*)
FROM [bronze].[crm_sales_details]
GROUP BY [sls_ord_num]
HAVING COUNT(*) > 1 OR [sls_ord_num] IS NULL

-- Validate sls_prd_key against prd_key
SELECT *
FROM [bronze].[crm_sales_details]
WHERE sls_prd_key NOT IN (
  SELECT [prd_key] FROM [silver].[crm_prd_info]
)

-- Check sls_order_dt validity
SELECT [sls_order_dt]
FROM [bronze].[crm_sales_details]
WHERE sls_order_dt <= 0 OR sls_order_dt IS NULL

-- Check if date length is correct
SELECT NULLIF(sls_order_dt, 0) AS sls_order_dt
FROM [bronze].[crm_sales_details]
WHERE LEN(sls_order_dt) != 8
-- OR sls_order_dt < 19000101

-- Check if ship date is before order date
SELECT 
  sls_order_dt, 
  CAST(CAST(sls_ship_dt AS nvarchar) AS date) AS sls_ship_dt
FROM [bronze].[crm_sales_details]
WHERE sls_order_dt > sls_ship_dt

-- Validate sales amount
SELECT 
  sls_sales AS sls_sales_old,
  sls_quantity,
  sls_price AS sls_price_old,
  CASE 
    WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
    THEN sls_quantity * ABS(sls_price)
    ELSE sls_sales 
  END AS sls_sales,
  CASE 
    WHEN sls_price IS NULL OR sls_price <= 0 
    THEN sls_sales / NULLIF(sls_quantity, 0)
    ELSE sls_price 
  END AS sls_price
FROM [bronze].[crm_sales_details]
WHERE sls_sales != sls_quantity * sls_price
  OR sls_sales IS NULL 
  OR sls_quantity IS NULL 
  OR sls_price IS NULL 
  OR sls_sales <= 0 
  OR sls_quantity <= 0 
  OR sls_price <= 0
ORDER BY sls_price, sls_quantity, sls_sales

---------------------------------------------------------
------------------- ERP_CUST_AZ12 CHECKS ----------------
---------------------------------------------------------

-- Raw data
SELECT * FROM [bronze].[erp_CUST_AZ12]

-- Duplicated CID
SELECT [CID], COUNT(*)
FROM [bronze].[erp_CUST_AZ12]
GROUP BY [CID]
HAVING COUNT(*) > 1

-- Distinct GEN values
SELECT DISTINCT [GEN]
FROM [bronze].[erp_CUST_AZ12]

-- Check BDATE format and future dates
SELECT [BDATE], LEN([BDATE])
FROM [bronze].[erp_CUST_AZ12]
WHERE LEN([BDATE]) != 10 OR [BDATE] IS NULL

SELECT [BDATE]
FROM [bronze].[erp_CUST_AZ12]
WHERE [BDATE] > GETDATE()

SELECT [BDATE],
  CASE 
    WHEN [BDATE] > GETDATE() THEN NULL 
    ELSE [BDATE] 
  END AS [BDATE]
FROM [bronze].[erp_CUST_AZ12]

-- Normalize GEN
SELECT DISTINCT [GEN]
FROM (
  SELECT [CID],
    CASE 
      WHEN UPPER(TRIM([GEN])) IN ('F', 'FEMALE') THEN 'FEMALE'
      WHEN UPPER(TRIM([GEN])) IN ('M', 'MALE') THEN 'MALE'
      ELSE 'N.A'
    END AS [GEN],
    [BDATE]
  FROM [bronze].[erp_CUST_AZ12]
) AS GENDER

---------------------------------------------------------
------------------- ERP_LOC_A101 CHECKS -----------------
---------------------------------------------------------

-- Match CID to cst_key (remove dashes)
SELECT REPLACE(CID, '-', '') AS CID
FROM [bronze].[erp_LOC_A101]
WHERE REPLACE(CID, '-', '') NOT IN (
  SELECT [cst_key] FROM [silver].[crm_cust_info]
)

-- Normalize CNTRY values
SELECT DISTINCT [CNTRY]
FROM (
  SELECT 
    CASE 
      WHEN TRIM([CNTRY]) = 'DE' THEN 'GERMANY'
      WHEN TRIM([CNTRY]) IN ('US', 'USA') THEN 'UNITED STATES'
      WHEN [CNTRY] IS NULL OR [CNTRY] = '' THEN 'N/A'
      ELSE TRIM(UPPER([CNTRY]))
    END AS [CNTRY]
  FROM [bronze].[erp_LOC_A101]
) AS DD

---------------------------------------------------------
------------------- ERP_PX_CAT_G1V2 CHECKS --------------
---------------------------------------------------------

-- Check missing cat_id in silver.crm_prd_info
SELECT [ID]
FROM [bronze].[erp_PX_CAT_G1V2]
WHERE [ID] NOT IN (
  SELECT [cat_id] FROM [silver].[crm_prd_info]
)

-- Trim CAT and SUBCAT
SELECT *
FROM [bronze].[erp_PX_CAT_G1V2]
WHERE CAT != TRIM(CAT) OR SUBCAT != TRIM(SUBCAT)

-- Distinct CAT and MAINTENANCE values
SELECT DISTINCT [CAT] FROM [bronze].[erp_PX_CAT_G1V2]
SELECT DISTINCT [MAINTENANCE] FROM [bronze].[erp_PX_CAT_G1V2]

