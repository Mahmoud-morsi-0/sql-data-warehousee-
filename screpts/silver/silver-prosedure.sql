-- =============================================
-- Create date:   [2025-08-03]
-- Description:   Data load procedure for Silver layer.
--                Cleans, transforms, and loads data
--                from Bronze layer into Silver layer tables.
--
-- Tables involved:
--    - silver.crm_cust_info
--    - silver.crm_prd_info
--    - silver.crm_sales_details
--    - silver.erp_CUST_AZ12
--    - silver.erp_LOC_A101
--    - silver.erp_PX_CAT_G1V2
-- =============================================

CREATE OR ALTER PROCEDURE SILVER.LOAD_SILVER AS 
BEGIN
	DECLARE @start_date DATETIME, @end_date DATETIME, @strt_all DATETIME, @end_all DATETIME

	BEGIN TRY

		SET @strt_all = GETDATE()

		PRINT '----------------------------------'
		PRINT 'Truncating table to avoid duplicates'
		TRUNCATE TABLE silver.crm_cust_info;

		PRINT 'Loading silver.crm_cust_info ...';
		SET @start_date = GETDATE();

		PRINT 'Inserting data'
		INSERT INTO silver.crm_cust_info (
			cst_id,
			cst_key,
			cst_firstname,
			cst_lastname,
			cst_marital_status,
			cst_gndr,
			cst_create_date
		)
		SELECT 
			cst_id,
			cst_key,
			TRIM(cst_firstname) AS cst_firstname,
			TRIM(cst_lastname) AS cst_lastname,
			CASE
				WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'MARRIED'    -- Data standardization
				WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'SINGLE'
				ELSE 'n/a'
			END AS cst_marital_status,
			CASE
				WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'FEMALE'              -- Data standardization
				WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'MALE'
				ELSE 'n/a'
			END AS cst_gndr,
			cst_create_date
		FROM (
			SELECT *,
				-- duplcated cast_id , Keep the latest record for each cst_id using row_number over cst_create_date
				ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag
			FROM [bronze].[crm_cust_info]
		) t
		WHERE flag = 1 AND cst_id IS NOT NULL;

		SET @end_date = GETDATE();
		PRINT 'Load duration: ' + CAST(DATEDIFF(SECOND, @start_date, @end_date) AS NVARCHAR) + ' seconds';
		PRINT '=================================================';

		-- Loading crm_prd_info
		PRINT '----------------------------------'
		PRINT 'Truncating table to avoid duplicates'
		TRUNCATE TABLE silver.crm_prd_info;

		PRINT 'Loading silver.crm_prd_info ...';
		SET @start_date = GETDATE();

		PRINT 'Inserting data'
		INSERT INTO silver.crm_prd_info (
			prd_id,
			cat_id,
			prd_key,
			prd_nm,
			prd_cost,
			prd_line,
			prd_start_dt,
			prd_end_dt
		)
		SELECT 
			prd_id,
			REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
			SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,
			prd_nm,
			ISNULL(prd_cost, 0) AS prd_cost,
			CASE
				-- Translate codes to readable product lines
				WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'mountain'
				WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'road'
				WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'other sales'
				WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'touring'
				ELSE 'n/a'
			END AS prd_line,
			CAST(prd_start_dt AS DATE) AS prd_start_dt,   -- Keep only the date part
			CAST(LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) AS DATE) AS prd_end_dt -- Build prd_end_dt from next start date
		FROM [bronze].[crm_prd_info];

		SET @end_date = GETDATE();
		PRINT 'Load duration: ' + CAST(DATEDIFF(SECOND, @start_date, @end_date) AS NVARCHAR) + ' seconds';
		PRINT '=================================================';

		-- Loading crm_sales_details
		PRINT '----------------------------------'
		PRINT 'Truncating table to avoid duplicates'
		PRINT 'Loading [silver].[crm_sales_details] ...';
		SET @start_date = GETDATE();

		TRUNCATE TABLE [silver].[crm_sales_details];

		INSERT INTO [silver].[crm_sales_details](
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			sls_order_dt,
			sls_ship_dt,
			sls_due_dt,
			sls_sales,
			sls_quantity,
			sls_price
		)
		SELECT 
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			-- Convert invalid/zero dates to NULL
			CASE WHEN sls_order_dt = '0' OR LEN(sls_order_dt) != 8 THEN NULL ELSE CAST(CAST(sls_order_dt AS NVARCHAR) AS DATE) END AS sls_order_dt,
			CASE WHEN sls_ship_dt = '0' OR LEN(sls_ship_dt) != 8 THEN NULL ELSE CAST(CAST(sls_ship_dt AS NVARCHAR) AS DATE) END AS sls_ship_dt,
			CASE WHEN sls_due_dt = '0' OR LEN(sls_due_dt) != 8 THEN NULL ELSE CAST(CAST(sls_due_dt AS NVARCHAR) AS DATE) END AS sls_due_dt,
			-- Ensure sales = quantity * price if missing or incorrect
			CASE 
				WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
				THEN sls_quantity * ABS(sls_price)
				ELSE sls_sales 
			END AS sls_sales,
			sls_quantity,
			-- Recalculate price if invalid
			CASE 
				WHEN sls_price IS NULL OR sls_price <= 0
				THEN sls_sales / NULLIF(sls_quantity, 0)
				ELSE sls_price
			END AS sls_price
		FROM bronze.[crm_sales_details];

		SET @end_date = GETDATE();
		PRINT 'Load duration: ' + CAST(DATEDIFF(SECOND, @start_date, @end_date) AS NVARCHAR) + ' seconds';
		PRINT '=================================================';

		-- Loading erp_CUST_AZ12
		PRINT '----------------------------------'
		PRINT 'Truncating table to avoid duplicates'
		PRINT 'Loading [silver].erp_CUST_AZ12 ...';
		SET @start_date = GETDATE();

		TRUNCATE TABLE [silver].erp_CUST_AZ12;

		INSERT INTO silver.erp_CUST_AZ12 (
			CID,
			BDATE,
			GEN
		)
		SELECT 
			-- Strip NAS prefix if present
			CASE 
				WHEN CID LIKE 'NAS%' THEN SUBSTRING(CID, 4, LEN(CID))
				ELSE CID
			END AS CID,

			-- Convert to valid date or NULL
			----  WE PUT TRY_CONVERT() BECAUSE WE HAVE and-date values ' NULL '

			CASE 
				WHEN TRY_CONVERT(DATE, [BDATE]) IS NOT NULL AND TRY_CONVERT(DATE, [BDATE]) <= GETDATE() THEN TRY_CONVERT(DATE, [BDATE])
				ELSE NULL
			END AS BDATE,

			-- Normalize gender values
			CASE 
				WHEN UPPER(TRIM([GEN])) IN ('F', 'FEMALE') THEN 'FEMALE'
				WHEN UPPER(TRIM([GEN])) IN ('M', 'MALE') THEN 'MALE'
				ELSE 'N.A'
			END AS GEN
		FROM [bronze].[erp_CUST_AZ12];

		SET @end_date = GETDATE();
		PRINT 'Load duration: ' + CAST(DATEDIFF(SECOND, @start_date, @end_date) AS NVARCHAR) + ' seconds';
		PRINT '=================================================';

		-- Loading erp_LOC_A101
		PRINT '----------------------------------'
		PRINT 'Truncating table to avoid duplicates'
		PRINT 'Loading [silver].[erp_LOC_A101] ...';
		SET @start_date = GETDATE();

		TRUNCATE TABLE [silver].[erp_LOC_A101];

		INSERT INTO [silver].[erp_LOC_A101] ([CID],[CNTRY])
		SELECT 
			REPLACE(CID, '-', '') AS CID, -- Strip hyphens to match [cst_key]
			CASE 
				WHEN TRIM([CNTRY]) = 'DE' THEN 'GERMANY'
				WHEN TRIM([CNTRY]) IN ('US', 'USA') THEN 'UNITED STATES'
				WHEN [CNTRY] IS NULL OR [CNTRY] = '' THEN 'N/A'
				ELSE TRIM(UPPER([CNTRY]))
			END AS [CNTRY]
		FROM [bronze].[erp_LOC_A101];

		SET @end_date = GETDATE();
		PRINT 'Load duration: ' + CAST(DATEDIFF(SECOND, @start_date, @end_date) AS NVARCHAR) + ' seconds';
		PRINT '=================================================';

		-- Loading erp_PX_CAT_G1V2
		PRINT '----------------------------------'
		PRINT 'Truncating table to avoid duplicates'
		PRINT 'Loading [silver].[erp_PX_CAT_G1V2] ...';
		SET @start_date = GETDATE();

		TRUNCATE TABLE [silver].[erp_PX_CAT_G1V2];

		INSERT INTO [silver].[erp_PX_CAT_G1V2] ([ID],[CAT],[SUBCAT],[MAINTENANCE])
		SELECT 
			[ID], [CAT], [SUBCAT], [MAINTENANCE]
		FROM [BRONZE].[erp_PX_CAT_G1V2];

		SET @end_date = GETDATE();
		PRINT 'Load duration: ' + CAST(DATEDIFF(SECOND, @start_date, @end_date) AS NVARCHAR) + ' seconds';
		PRINT '=================================================';

		SET @end_all = GETDATE();
		PRINT 'Total duration to insert all tables: ' + CAST(DATEDIFF(SECOND, @strt_all, @end_all) AS NVARCHAR) + ' seconds';

	END TRY

	BEGIN CATCH
		PRINT '=========================================';
		PRINT '❌ Error occurred during load process.';
		PRINT 'Error message: ' + ERROR_MESSAGE();
		PRINT 'Error number: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT '=========================================';
	END CATCH
END
