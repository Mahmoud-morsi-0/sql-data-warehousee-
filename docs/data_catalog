# 📊 Gold Layer Data Catalog (Enterprise Data Warehouse)

## Overview
The **Gold Layer** represents the business-level data model of our Enterprise Data Warehouse (EDW). It contains clean, conformed, and analytics-ready data designed to support reporting, dashboards, and strategic analysis. The Gold Layer consists of **dimension tables** and **fact tables** that capture key business metrics.

---

## 📁 Tables

### 1. `gold.dim_customers`
**Purpose**: Stores enriched customer details including demographics and geographic information.

| Column Name     | Data Type      | Description                                                                 |
|------------------|------------------|-----------------------------------------------------------------------------|
| `customer_key`   | INT              | Surrogate key uniquely identifying each customer.                          |
| `customer_id`    | INT              | Unique internal ID assigned to each customer.                              |
| `customer_number`| NVARCHAR(50)     | Alphanumeric code for external tracking and reference.                     |
| `first_name`     | NVARCHAR(50)     | Customer's first name.                                                     |
| `last_name`      | NVARCHAR(50)     | Customer's last or family name.                                            |
| `country`        | NVARCHAR(50)     | Country of residence (e.g., 'Australia').                                  |
| `marital_status` | NVARCHAR(50)     | Marital status (e.g., 'Married', 'Single').                                |
| `gender`         | NVARCHAR(50)     | Gender (e.g., 'Male', 'Female', 'n/a').                                    |
| `birthdate`      | DATE             | Date of birth in `YYYY-MM-DD` format.                                      |
| `create_date`    | DATE             | Date when the customer record was created.                                 |

---

### 2. `gold.dim_products`
**Purpose**: Contains product attributes and classification data.

| Column Name         | Data Type      | Description                                                                 |
|----------------------|------------------|-----------------------------------------------------------------------------|
| `product_key`        | INT              | Surrogate key for each product record.                                     |
| `product_id`         | INT              | Internal product ID.                                                       |
| `product_number`     | NVARCHAR(50)     | Alphanumeric product code.                                                 |
| `product_name`       | NVARCHAR(50)     | Full name/description of the product.                                      |
| `category_id`        | NVARCHAR(50)     | ID linking to high-level product category.                                 |
| `category`           | NVARCHAR(50)     | Broad product classification (e.g., Bikes, Components).                    |
| `subcategory`        | NVARCHAR(50)     | More detailed classification (e.g., product type).                         |
| `maintenance_required` | NVARCHAR(50)   | Indicates if maintenance is required (Yes/No).                             |
| `cost`               | INT              | Product base cost.                                                         |
| `product_line`       | NVARCHAR(50)     | Product line or series (e.g., Road, Mountain).                             |
| `start_date`         | DATE             | Availability start date of the product.                                    |

---

### 3. `gold.fact_sales`
**Purpose**: Holds transactional-level sales data.

| Column Name     | Data Type      | Description                                                                 |
|------------------|------------------|-----------------------------------------------------------------------------|
| `order_number`   | NVARCHAR(50)     | Unique sales order identifier (e.g., 'SO54496').                           |
| `product_key`    | INT              | Foreign key to `dim_products`.                                             |
| `customer_key`   | INT              | Foreign key to `dim_customers`.                                            |
| `order_date`     | DATE             | Date the order was placed.                                                 |
| `shipping_date`  | DATE             | Date the order was shipped.                                                |
| `due_date`       | DATE             | Payment due date.                                                          |
| `sales_amount`   | INT              | Total sale value (e.g., in whole currency units).                          |
| `quantity`       | INT              | Number of product units sold.                                              |
| `price`          | INT              | Price per product unit.                                                    |

---

## 🔍 Notes
- All **surrogate keys** (e.g., `customer_key`, `product_key`) are used for efficient joins.
- Dimension tables follow a slowly changing dimension (SCD) strategy where needed.
- Fact tables are designed in a **star schema** structure for optimized analytics performance.
- Date formats follow the `YYYY-MM-DD` convention.

---

## ✅ Use Cases
- Customer behavior analysis
- Product category sales trends
- Regional performance reporting
- Marketing segmentation and lifetime value (LTV) tracking

---

## 📂 Layer: Gold (Presentation Layer)
This is the **final** curated layer exposed to BI tools (Power BI, Tableau, Looker), stakeholders, and executive dashboards.
