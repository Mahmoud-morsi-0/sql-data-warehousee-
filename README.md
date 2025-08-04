# 🏢 Data Warehouse and Analytics Project

Welcome to the **Data Warehouse and Analytics Project**! 🚀  
This repository showcases a full-scale implementation of a modern data warehouse and analytics solution, using industry best practices in data modeling, ETL, and business intelligence. It is designed as a portfolio project for showcasing practical skills in data engineering and analytics.

---

## 🧱 Data Architecture

This project follows the **Medallion Architecture**, implementing three layers:

- **🔹 Bronze Layer**:  
  Raw data ingested as-is from the source systems. Source data is provided as CSV files (ERP and CRM), and ingested into SQL Server.

- **🔸 Silver Layer**:  
  Cleansed and transformed data. This layer involves:
  - Data quality checks  
  - Standardization of formats  
  - Basic normalization  
  - Deduplication

- **⭐ Gold Layer**:  
  Business-ready, curated data. This layer includes:
  - Star schema modeling (Fact & Dimension tables)  
  - Data aggregated and optimized for analytics  
  - User-friendly naming conventions

---

## 🔄 ETL Pipelines

ETL processes are designed using SQL scripts and procedures:

- **Extract** from CSV files (ERP and CRM)
- **Transform** using SQL (cleansing, deduplication, joins)
- **Load** into separate Bronze, Silver, and Gold tables

---

## 🧩 Data Modeling

Data in the **Gold Layer** is structured into a **star schema** with:

- **Fact Tables**:  
  - `fact_sales`  
  - `fact_customer_activity`

- **Dimension Tables**:  
  - `dim_product`  
  - `dim_customer`  
  - `dim_time`  
  - `dim_region`

---

## 📊 Analytics & Reporting

Using SQL-based reporting and dashboards, the following business insights were derived:

- 📈 **Sales Trends**  
- 🧍‍♂️ **Customer Behavior**  
- 🛍️ **Product Performance**

These insights are prepared for use in **Power BI**, **Tableau**, or **Excel** dashboards to support strategic decision-making.

---

## 📦 Project Scope

- ✔ Data ingestion from ERP & CRM systems (CSV format)
- ✔ No historical tracking (latest snapshot only)
- ✔ Data quality improvement and error resolution
- ✔ Integration into a unified data model
- ✔ Clear documentation for stakehold
