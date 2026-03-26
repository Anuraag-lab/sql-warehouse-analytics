# 🏭 SQL Warehouse Analytics

A complete end-to-end data analytics project built on **SQL Server** using a **star schema (gold layer)** architecture. The project covers database design, advanced SQL analytics, customer & product reporting, and business KPIs — all in pure T-SQL.

---

## 📌 Project Overview

| Detail | Info |
|--------|------|
| **Tool** | SQL Server (T-SQL) |
| **Database** | DataWarehouseAnalytics |
| **Schema** | Gold Layer (dim/fact star model) |
| **Total Lines** | 476+ lines of SQL |
| **Data Range** | Dec 2010 – Jan 2014 (4 years) |

---

## 🗂️ Database Schema

**Gold Layer — Star Schema:**

```
gold.dim_customers     → Customer demographics & geography
gold.dim_products      → Product catalog with category & cost
gold.fact_sales        → Transactional sales data (orders, revenue, quantity)
```

---

## 🔍 Key Findings

| Insight | Value |
|---------|-------|
| 🚴 Bikes revenue share | **96.46%** of total revenue |
| 👑 VIP customers | **1,582** (high spend + lifespan > 12 months) |
| 🆕 New customers | **14,704** |
| 📦 Regular customers | **2,198** |
| 🏆 Top product | Mountain-200 Black-46 — $1,373,454 revenue |
| 🌍 Top market | United States |
| 📉 Worst performers | Racing Socks-L ($2,430), Racing Socks-M ($2,682) |

---

## ⚙️ What This Project Covers

### 1. Database & Schema Setup
- Created `DataWarehouseAnalytics` database from scratch
- Built gold schema with `dim_customers`, `dim_products`, and `fact_sales` tables

### 2. Time Series Analysis
- Monthly and yearly sales trends
- Cumulative (running total) sales using `SUM() OVER()`
- Year-over-year product performance comparison using CTEs + window functions

### 3. Category & Product Analysis
- Revenue contribution by category (Bikes / Accessories / Clothing)
- Product segmentation: High-performer / Mid-range / Low-performer
- Cost range bucketing using `CASE` statements
- Top & bottom 5 products by revenue with `ROW_NUMBER()`

### 4. Customer Segmentation
- VIP / Regular / New segments based on lifespan and spending
- Top 10 highest revenue customers
- 3 customers with fewest orders identified

### 5. Reports & Views
- `gold.report_customers` — full customer KPI view:
  - Total orders, sales, quantity, products
  - Lifespan, recency, avg order value, avg monthly spend
- `gold.report_products` — full product KPI view:
  - Revenue, customers, orders, avg selling price, avg monthly revenue

---

## 🛠️ SQL Concepts Used

- `CTEs` (Common Table Expressions)
- `Window Functions` — `SUM() OVER()`, `AVG() OVER()`, `ROW_NUMBER() OVER()`
- `CASE` statements for segmentation & bucketing
- `INNER JOIN` / `LEFT JOIN` across fact and dimension tables
- `DATETRUNC`, `DATEDIFF`, `DATEPART` for date calculations
- `CREATE VIEW` for reusable reporting layers
- `INFORMATION_SCHEMA` for schema exploration

---

## 📁 Files

```
sql-warehouse-analytics/
│
├── dataset.csv          ← Raw source data (customers, products & sales)
├── queries.sql          ← All analytics queries (476+ lines)
└── README.md
```

---

## 🚀 How to Run

1. Open **SQL Server Management Studio (SSMS)**
2. Run the database & schema creation block first (lines 1–78)
3. Load your data into the gold layer tables
4. Run analytics queries section by section
5. Execute the `CREATE VIEW` statements to build the reporting layer

---

## 📊 Sample Results

**Category Revenue Contribution:**
| Category | Total Sales | % of Total |
|----------|------------|------------|
| Bikes | $28,316,272 | 96.46% |
| Accessories | $700,262 | 2.39% |
| Clothing | $339,716 | 1.16% |

**Customer Segments:**
| Segment | Total Customers |
|---------|----------------|
| New | 14,704 |
| Regular | 2,198 |
| VIP | 1,582 |

---

## 👤 Author

**Anuraag Kaushal**
[GitHub Profile](https://github.com/DataWithBaraa) | [LinkedIn](https://www.linkedin.com/in/)

