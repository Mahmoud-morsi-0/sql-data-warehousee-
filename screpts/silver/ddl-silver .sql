-- Description:
-- This SQL script creates the necessary tables in the 'silver' layer of a Data Warehouse pipeline. 
-- These tables store cleaned and standardized data from CRM and ERP systems, including customer info, product info, 
-- sales details, customer birth and gender data, location data, and product category metadata.
-- Each table includes a 'dwh_insert_date' column to track when the data was inserted into the silver layer.
-- The script ensures no duplicate tables by dropping existing ones before creation.



IF OBJECT_ID('silver.crm_cust_info','U' ) IS NOT NULL 
	DROP TABLE silver.crm_cust_info ; 
CREATE TABLE silver.crm_cust_info(
	cst_id	INT ,
	cst_key	NVARCHAR(50),
	cst_firstname	NVARCHAR(50),
	cst_lastname	NVARCHAR(50),
	cst_marital_status	NVARCHAR(50),
	cst_gndr	NVARCHAR(50),
	cst_create_date DATE ,
	dwh_insert_date DATETIME2 DEFAULT GETDATE()  --EXTRA COLUMN TO GET THE DATE AND TIME THAT DTA WILL BE INSERTED 
	); 

IF OBJECT_ID('silver.crm_prd_info','U' ) IS NOT NULL 
	DROP TABLE silver.crm_prd_info ; 
CREATE TABLE silver.crm_prd_info(
	
	prd_id	INT ,	
	prd_key	NVARCHAR(50),
	cat_id NVARCHAR(50),--- we add this coulmn onn transformation 
	prd_nm	NVARCHAR(50),
	prd_cost INT ,
	prd_line NVARCHAR(50),
	prd_start_dt	DATE ,--- we changed it from DATETIME to date because we chande it in the transformation 
	prd_end_dt DATE ,--- we changed it from DATETIME to date because we chande it in the transformation 
	dwh_insert_date DATETIME2 DEFAULT GETDATE()--EXTRA COLUMN TO GET THE DATE AND TIME THAT DTA WILL BE INSERTED 

	)

IF OBJECT_ID('silver.crm_sales_details','U' ) IS NOT NULL 
	DROP TABLE silver.crm_sales_details ; 
CREATE TABLE silver.crm_sales_details(
		sls_ord_num	NVARCHAR(50),
		sls_prd_key	NVARCHAR(50),
		sls_cust_id	INT ,
		sls_order_dt	date ,---update the data  type from int to date 
		sls_ship_dt	date  ,
		sls_due_dt	date,
		sls_sales	INT ,
		sls_quantity	INT ,
		sls_price INT ,
		dwh_insert_date DATETIME2 DEFAULT GETDATE()--EXTRA COLUMN TO GET THE DATE AND TIME THAT DTA WILL BE INSERTED 

		)

IF OBJECT_ID('silver.erp_CUST_AZ12','U' ) IS NOT NULL 
		DROP TABLE silver.erp_CUST_AZ12; 
CREATE TABLE silver.erp_CUST_AZ12(
		
		CID		NVARCHAR(50),
		BDATE	DATE ,
		GEN		NVARCHAR(50),
		dwh_insert_date DATETIME2 DEFAULT GETDATE()--EXTRA COLUMN TO GET THE DATE AND TIME THAT DTA WILL BE INSERTED 

		)


IF OBJECT_ID('silver.erp_LOC_A101','U' ) IS NOT NULL 
		DROP TABLE silver.erp_LOC_A101; 
CREATE TABLE silver.erp_LOC_A101(
		CID		NVARCHAR(50),
		CNTRY NVARCHAR(50),
		dwh_insert_date DATETIME2 DEFAULT GETDATE()--EXTRA CLOUMN TO GET THE DATE AND TIME THAT DTA WILL BE INSERTED 

		)

IF OBJECT_ID('silver.erp_PX_CAT_G1V2','U' ) IS NOT NULL 
		DROP TABLE silver.erp_PX_CAT_G1V2; 
CREATE TABLE silver.erp_PX_CAT_G1V2(
		ID	NVARCHAR(50),
		CAT	NVARCHAR(50),
		SUBCAT	NVARCHAR(50),
		MAINTENANCE NVARCHAR(50),
		dwh_insert_date DATETIME2 DEFAULT GETDATE()--EXTRA CLOUMN TO GET THE DATE AND TIME THAT DTA WILL BE INSERTED 


		)
