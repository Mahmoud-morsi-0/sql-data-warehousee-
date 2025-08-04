/*
===========================================================================================
📄 DATA QUALITY CHECK SCRIPT: CRM + ERP Integration Validation
===========================================================================================

🧾 Description:
This SQL script performs various data quality checks on integrated CRM and ERP datasets 
during the data warehouse silver and gold layer transformation stages. The checks include:

1. Gender consistency between CRM and ERP sources.
2. Key integrity between fact and dimension tables.
3. Duplicate detection in product records.
4. Validation of active product data.

✅ This script supports ensuring clean, reliable inputs before loading into Gold Layer.

--------------------------------------------------------------------------------------------
*/


/* 
===========================================================================================
🔎 1. GENDER CHECK — Validating Gender Consistency Across CRM and ERP
===========================================================================================

🎯 Goal:
- Check for mismatches in gender values between CRM (ci.cst_gndr) and ERP (ca.GEN).
- Use ci.cst_gndr as the primary field.
- If ci.cst_gndr is 'N/A', fallback to ca.GEN (or default 'N/A' if null).

📝 Notes:
- COALESCE is used to handle null values in ca.GEN.
- 'N.A' and 'N/A' are both considered invalid or missing data.
*/

SELECT DISTINCT
  CASE 
    WHEN ci.cst_gndr != UPPER('N/A') THEN ci.cst_gndr
    WHEN ca.GEN = UPPER('N.A') THEN 'N/A'
    ELSE COALESCE(ca.GEN, 'N/A') 
    -- COALESCE: returns ca.GEN if not NULL, else returns 'N/A'
  END AS GENDER,
  ci.cst_gndr AS CRM_GENDER,
  ca.GEN AS ERP_GENDER
FROM [silver].[crm_cust_info] AS ci
LEFT JOIN [silver].[erp_CUST_AZ12] AS ca
  ON ci.cst_key = ca.cid
LEFT JOIN [silver].[erp_LOC_A101] AS la
  ON ci.cst_key = la.CID
WHERE ci.cst_gndr != ca.GEN;



/* 
===========================================================================================
🔎 2. FACT-DIMENSION KEY INTEGRITY CHECK — GOLD LAYER
===========================================================================================

🎯 Goal:
- Ensure all keys in the FACT_SALES table properly match DIM_CUST and DIM_PROD.
- Identify rows where customer_key has no match in DIM_CUST (should be cleaned or excluded).
*/

SELECT * 
FROM GOLD.FACT_SALES AS fs
LEFT JOIN GOLD.DIM_PROD AS dp
  ON fs.PRODUCT_KEY = dp.PRODUCT_KEY
LEFT JOIN GOLD.DIM_CUST AS ds
  ON fs.CUSTOMER_KEY = ds.CUSTOMER_KEY
WHERE fs.CUSTOMER_KEY IS NULL;  -- 🔴 Missing Customer Reference



/* 
===========================================================================================
🔎 3. DUPLICATE DETECTION — PRD_ID in CRM Product Info
===========================================================================================

🎯 Goal:
- Detect duplicate PRD_ID entries in [silver].[crm_prd_info]
- This ensures PRD_ID is unique for product records
*/

SELECT 
  PRD_ID,
  COUNT(*) AS DUP_COUNT
FROM [silver].[crm_prd_info]
GROUP BY PRD_ID
HAVING COUNT(*) > 1;  -- 🔴 Duplicate Found



/* 
===========================================================================================
🔎 4. PRODUCT KEY DUPLICATION — ONLY ACTIVE PRODUCTS
===========================================================================================

🎯 Goal:
- Check if PRD_KEY values are duplicated in current (active) products.
- Only include records where prd_end_dt IS NULL.
- Join category metadata to assist in reviewing duplicate products.
*/

SELECT 
  prd_key,
  COUNT(*) AS DUP_COUNT
FROM (
  SELECT 
    pn.prd_id,
    pn.cat_id,
    pn.prd_key,
    pn.prd_nm,
    pn.prd_cost,
    pn.prd_line,
    pn.prd_start_dt,
    -- pn.prd_end_dt removed to focus on current active products
    pc.cat,
    pc.subcat,
    pc.maintenance
  FROM [silver].[crm_prd_info] AS pn
  LEFT JOIN [silver].[erp_PX_CAT_G1V2] AS pc
    ON pn.cat_id = pc.ID
  WHERE pn.prd_end_dt IS NULL  -- ✅ Only current data
) AS current_products
GROUP BY prd_key
HAVING COUNT(*) > 1;  -- 🔴 Duplicate PRD_KEY
