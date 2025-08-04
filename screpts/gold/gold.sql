/********************************************************************************************
*  Description:
*    This script creates 3 core views for the Gold Layer of a star schema data model:
*    
*    1. GOLD.DIM_CUST: Customer dimension containing cleaned and enriched customer details.
*    2. GOLD.DIM_PROD: Product dimension with categorized and active product data.
*    3. GOLD.FACT_SALES: Sales fact table joins dimension tables with sales transactions.
*
*    The views are built on top of the Silver layer, with joins, renaming, filtering, and 
*    surrogate key generation (using ROW_NUMBER) to enable dimensional modeling.
********************************************************************************************/

-- =========================================================================================
-- 1. DIM_CUST: Customer Dimension View
-- =========================================================================================
CREATE VIEW GOLD.DIM_CUST AS
SELECT 
    ROW_NUMBER() OVER (ORDER BY ci.cst_id) AS customer_key, -- Surrogate key for DW model
    ci.cst_id AS customer_id,                                -- Natural customer ID
    ci.cst_key AS customer_number,                           -- Internal CRM customer number
    ci.cst_firstname AS first_name,                          -- Customer's first name
    ci.cst_lastname AS last_name,                            -- Customer's last name

    -- Gender handling logic:
    -- If gender in CRM is not 'N/A', take it
    -- Else, try gender from ERP table; if NULL, use 'N/A'
    CASE 
        WHEN ci.cst_gndr != 'N/A' THEN ci.cst_gndr
        WHEN ca.GEN = 'N.A' THEN 'N/A'
        ELSE COALESCE(UPPER(ca.GEN), 'N/A') 
  --- COALESCE fun :  If ca.GEN has a value (i.e., not NULL),
  ---return that value If ca.GEN is NULL, return 'N/A'..
    END AS gender,

    ci.cst_marital_status AS marital_status,                 -- Marital status of customer
    la.cntry AS country,                                     -- Country from location table
    ca.bdate AS birthdate,                                   -- Date of birth from ERP
    ci.cst_create_date AS create_date                        -- Customer creation date
FROM silver.crm_cust_info AS ci
LEFT JOIN silver.erp_CUST_AZ12 AS ca
    ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_LOC_A101 AS la
    ON ci.cst_key = la.CID;
------after re-naming the coulmn, 
--re-order the coulmn to be more derduble and make since with the reader 


-- =========================================================================================
-- 2. DIM_PROD: Product Dimension View
-- =========================================================================================
CREATE VIEW GOLD.DIM_PROD AS 
SELECT 
    ROW_NUMBER() OVER (ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key, -- Surrogate key
  --prd_start_dt — Primary sort:
  --This ensures products are ordered by when they were introduced.
  --prd_key — Secondary sort:
  --If two products started on the same date, this provides a consistent tie-breaker 

    pn.prd_id AS product_id,                      -- External product ID
    pn.prd_key AS product_number,                 -- Internal product number
    pn.prd_nm AS product_name,                    -- Product name
    pn.cat_id AS category_id,                     -- Category ID
    pc.cat AS category,                           -- Category label
    pc.subcat AS subcategory,                     -- Subcategory label
    pc.maintenance,                               -- Maintenance status (e.g., seasonal, discontinued)
  ----pn.prd_end_dt, AFTER DESIDED WE WILL WORK ON THE CURNT DATA WE DELET THE END_DATE FROM OUR VIEW 
    pn.prd_cost AS cost,                          -- Product base cost
    pn.prd_line AS product_line,                  -- Product line/brand/series
    pn.prd_start_dt AS start_date                 -- Launch/start date of the product
FROM silver.crm_prd_info AS pn
LEFT JOIN silver.erp_PX_CAT_G1V2 AS pc
    ON pn.cat_id = pc.ID
WHERE pn.prd_end_dt IS NULL                      -- Only include currently active products


-- =========================================================================================
-- 3. FACT_SALES: Sales Fact Table
-- =========================================================================================
CREATE VIEW GOLD.FACT_SALES AS
SELECT
    sd.sls_ord_num AS order_number,                -- Unique order number
    DC.customer_key,                               -- FK to DIM_CUST (surrogate key)
    DP.product_key,                                -- FK to DIM_PROD (surrogate key)
    --sd.sls_prd_key,  ----WE WELL EGNORE THIS COLUMN BECAUSE WE GUST NED IT FOR JOIN THE TABLES ALL WE NEED THE KEY THAT WE WAS GENERATED 
  	--sd.sls_cust_id, ---WE WELL EGNORE THIS COLUMN BECAUSE WE GUST NED IT FOR JOIN THE TABLES. ALL WE NEED THE KEY THAT WE WAS GENERATED 
    -- Transaction-level details:
    sd.sls_order_dt AS order_date,                 -- When the order was placed
    sd.sls_ship_dt AS shipping_date,               -- When the order was shipped
    sd.sls_due_dt AS due_date,                     -- Expected delivery date
    sd.sls_sales AS sales_amount,                  -- Total sales value
    sd.sls_quantity AS quantity,                   -- Number of units sold
    sd.sls_price                                    -- Price per unit
FROM silver.crm_sales_details AS sd
LEFT JOIN GOLD.DIM_CUST AS DC
    ON sd.sls_cust_id = DC.customer_id
LEFT JOIN GOLD.DIM_PROD AS DP 
    ON sd.sls_prd_key = DP.product_number;
