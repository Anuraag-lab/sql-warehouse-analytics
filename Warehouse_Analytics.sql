/*
=============================================================
Create Database and Schemas
=============================================================
Script Purpose:
    This script creates a new database named 'DataWarehouseAnalytics' after checking if it already exists. 
    If the database exists, it is dropped and recreated. Additionally, this script creates a schema called gold
	
WARNING:
    Running this script will drop the entire 'DataWarehouseAnalytics' database if it exists. 
    All data in the database will be permanently deleted. Proceed with caution 
    and ensure you have proper backups before running this script.
*/

USE master;
GO

-- Drop and recreate the 'DataWarehouseAnalytics' database
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouseAnalytics')
BEGIN
    ALTER DATABASE DataWarehouseAnalytics SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DataWarehouseAnalytics;
END;
GO

-- Create the 'DataWarehouseAnalytics' database
CREATE DATABASE DataWarehouseAnalytics;
GO

USE DataWarehouseAnalytics;
GO

-- Create Schemas

CREATE SCHEMA gold;
GO

CREATE TABLE gold.dim_customers(
	customer_key int,
	customer_id int,
	customer_number nvarchar(50),
	first_name nvarchar(50),
	last_name nvarchar(50),
	country nvarchar(50),
	marital_status nvarchar(50),
	gender nvarchar(50),
	birthdate date,
	create_date date
);
GO

CREATE TABLE gold.dim_products(
	product_key int ,
	product_id int ,
	product_number nvarchar(50) ,
	product_name nvarchar(50) ,
	category_id nvarchar(50) ,
	category nvarchar(50) ,
	subcategory nvarchar(50) ,
	maintenance nvarchar(50) ,
	cost int,
	product_line nvarchar(50),
	start_date date 
);
GO

CREATE TABLE gold.fact_sales(
	order_number nvarchar(50),
	product_key int,
	customer_key int,
	order_date date,
	shipping_date date,
	due_date date,
	sales_amount int,
	quantity tinyint,
	price int 
);
GO

TRUNCATE TABLE gold.dim_customers;
GO

BULK INSERT gold.dim_customers
FROM 'C:\Users\Anuraag Kaushal\Downloads\cd6ca6c9bd83423ba5eabf06ab3d50f2\sql-data-analytics-project\datasets\flat-files\dim_customers.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);
GO

TRUNCATE TABLE gold.dim_products;
GO

BULK INSERT gold.dim_products
FROM 'C:\Users\Anuraag Kaushal\Downloads\cd6ca6c9bd83423ba5eabf06ab3d50f2\sql-data-analytics-project\datasets\flat-files\dim_products.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);
GO

TRUNCATE TABLE gold.fact_sales;
GO

BULK INSERT gold.fact_sales
FROM 'C:\Users\Anuraag Kaushal\Downloads\cd6ca6c9bd83423ba5eabf06ab3d50f2\sql-data-analytics-project\datasets\flat-files\fact_sales.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);
GO



-- Ananlysis Change over Time 
SELECT 
YEAR(order_date) AS order_year,
MONTH(order_date) AS order_month,
SUM(sales_amount) AS total_sales,
COUNT(DISTINCT customer_key) as total_customers,
SUM(quantity) as total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date) ,MONTH(order_date)
ORDER BY YEAR(order_date), MONTH(order_date);





--Cumulative Analysis
-- calculate total sales per month 
-- calculate running total sales over time 

SELECT 
order_month,
total_sales,
SUM(total_sales) OVER(PARTITION BY order_month ORDER BY order_month) AS running_total_sales
FROM
(
SELECT 
DATETRUNC(MONTH,order_date) AS order_month,
SUM(sales_amount) as total_sales 
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(MONTH,order_date) 
) t;


/* Analyse yearly performance of the product by comparing their sales 
	to both the average sales performance of the product and previous year sales */

WITH yearly_product_sales AS
(
	SELECT 
	YEAR(f.order_date) AS order_year,
	p.product_name,
	SUM(f.sales_amount) AS current_sales
	FROM gold.fact_sales  f
	LEFT JOIN gold.dim_products p 
	ON f.product_key = p.product_key
	WHERE f.order_date IS NOT NULL
	GROUP BY 
	YEAR(f.order_date),
	p.product_name
)
SELECT 
order_year,
product_name,
current_sales,
AVG(current_sales) OVER(PARTITION BY product_name) AS avg_sales,
current_sales - AVG(current_sales) OVER(PARTITION BY product_name) AS diff_avg,
CASE WHEN current_sales - AVG(current_sales) OVER(PARTITION BY product_name) > 0 THEN 'ABOVE_AVG'
	WHEN current_sales - AVG(current_sales) OVER(PARTITION BY product_name) < 0 THEN 'BELOW_AVG'
	ELSE 'AVG'
	END,
LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) py_sales,
current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) AS diff_py,
CASE 
	WHEN current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) >0 THEN 'Increase'
	WHEN current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) <0 THEN 'Decrease'
	ELSE 'No Change'
	END
FROM yearly_product_sales
ORDER BY product_name,order_year;


-- WHICH CATEGORY CONTRIBUTE TO OVERALL SALES
WITH category_sales AS (
SELECT 
category,
SUM(sales_amount) AS total_sales
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
ON p.product_key = f.product_key
GROUP BY category)

SELECT 
category,
total_sales,
SUM(total_sales) OVER() AS overall_sales,
CONCAT(ROUND(
    (CAST(total_sales AS FLOAT) / SUM(total_sales) OVER()) * 100,
    2
),'%')AS percent_of_total 
FROM category_sales
ORDER BY total_sales DESC;



/* Segment products into cost ranges and 
count how many products falls into each segment */

WITH product_segment AS (
	SELECT 
		product_key,
		product_name,
		cost,
	CASE 
		WHEN cost<100 THEN 'Below 100'
		WHEN cost BETWEEN 100 AND 500 THEN '100-500'
		WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
		ELSE 'ABOVE 1000'
	END cost_range
FROM 
	gold.dim_products)

SELECT 
	cost_range,
	COUNT(product_key) AS total_products
FROM product_segment
GROUP BY cost_range
ORDER BY total_products DESC;

/* Group customers into three segments based on there spending behaviour 
VIP : customers with atleat 12 months of history and spending more than 5000
Regular: customers with atleast 12 months of history and spending 5000 or less
New: customers with a lifespan less than 12 months
and find total number of customers by each group */ 


WITH customer_spending AS ( 
SELECT 
	c.customer_key,
	SUM(f.sales_amount) AS total_spending,
	MIN(f.order_date) AS first_order,
	MAX(f.order_date) AS last_order,
	DATEDIFF(MONTH,MIN(f.order_date),MAX(f.order_date)) AS lifespan
FROM gold.fact_sales f 
LEFT JOIN gold.dim_customers c
ON f.customer_key = c.customer_key
GROUP BY c.customer_key)

SELECT 
customer_segment,
COUNT(customer_key) AS total_customers 
FROM (
SELECT 
	customer_key,
	CASE 
	WHEN lifespan > 12 AND total_spending > 5000 THEN 'VIP'
	WHEN lifespan >=12 AND total_spending <=5000 THEN 'Regular'
	ELSE 'NEW'
END customer_segment
FROM customer_spending) t
GROUP BY customer_segment
ORDER BY total_customers;


/* 
=============================================================================================
Customer Report
=============================================================================================
Purpose :
	- This report consolidates key customer metrics and behaviours 
Highlights:
	1.Gathers essential fields such as names,ages and transaction details.
	2.Segments customers into categories (VIP, Regular, New) and age groups 
	3.Aggregate customer level metrics:
	 - total orders
	 - total sales
	 - total quantity purchased 
	 - total products 
	 - lifespan (in months)
	4.Calculate valuable KPIs:
	- recency (months since last order)
	- average order value 
	- average monthly spend
=================================================================================================
*/


CREATE VIEW gold.report_customers AS 
WITH base_query AS 
/*----------------------------------------------------------------------------------------------
1) Base Query : Retrives core columns from the tables 
------------------------------------------------------------------------------------------------*/
(
SELECT 
	f.order_number,
	f.product_key,
	f.order_date,
	f.sales_amount,
	f.quantity,
	c.customer_key,
	c.customer_number,
	CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
	DATEDIFF(YEAR,c.birthdate,GETDATE()) AS Age
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON f.customer_key = c.customer_key
WHERE order_date IS NOT NULL
) , customer_aggregation AS (
/*--------------------------------------------------------------------
Customer Aggregations : Summarises key metrics at customer level
---------------------------------------------------------------------*/
SELECT 
	customer_key,
	customer_number,
	customer_name,
	Age,
	COUNT(DISTINCT order_number) AS total_orders,
	SUM(sales_amount) AS total_sales,
	SUM(quantity) AS total_quantity,
	COUNT(DISTINCT product_key) AS total_products,
	MAX(order_date) AS last_order_date,
	DATEDIFF(MONTH,MIN(order_date),MAX(order_date)) AS lifespan
FROM base_query
GROUP BY 
	customer_key,
	customer_number,
	customer_name,
	Age )

SELECT 
customer_key,
customer_number,
customer_name,
Age,
CASE 
	WHEN Age < 20 THEN 'Under 20'
	WHEN Age between 20 and 29 THEN '20-29'
	WHEN Age between 30 and 39 THEN '30-39'
	WHEN Age between 40 and 49 THEN '40-49'
	ELSE '50 & ABOVE'
	END age_group,
CASE 
	WHEN lifespan > 12 AND total_sales > 5000 THEN 'VIP'
	WHEN lifespan >=12 AND total_sales <=5000 THEN 'Regular'
	ELSE 'NEW'
	END customer_segment,
total_orders,
total_sales,
total_quantity,
total_products,
last_order_date,
lifespan,
-- compute average order value
CASE WHEN total_orders = 0 THEN 0 
	ELSE total_sales / total_orders 
	END AS avg_order_value,
-- compute average monthly spent
CASE WHEN lifespan = 0 THEN total_sales
	ELSE total_sales / lifespan
	END AS avg_monthly_spend
FROM customer_aggregation;


SELECT * FROM gold.report_customers;

/*===============================================================================================================
Product Report
=================================================================================================================
Purpose:

- This report consolidates key product metrics and behaviours.

Highlights:
	1.Gathers essential fields such as product name,category,subcategory and cost.
	2.Segment products by revenue to identify High-performers, Mid-Range or Low-performers.
	3.Aggreagtes product-level metrics:
	 -total_orders
	 -total_sales
	 -total_quantity_sold
	 -total_customers (unique)
	 -lifespan(in months)
	4.Calculate valuable KPIs:
	 -recency(months since last sale)
	 -average order revenue 
	 -average monthly revenue

==================================================================================================================*/

/*---------------------------------------------------------------------
1) Base Query : Retrives core columns from the tables
----------------------------------------------------------------------*/
CREATE VIEW gold.report_products AS 
WITH Base_query AS (
SELECT 
f.order_number,
f.order_date,
f.customer_key,
f.sales_amount,
f.quantity,
p.product_key,
p.product_name,
p.category,
p.subcategory,
p.cost
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
ON f.product_key = p.product_key
WHERE order_date is not null
),product_aggregation AS (
/*---------------------------------------------------------------------
2) Product Aggregations: Summarizes key matrics at the product level
----------------------------------------------------------------------*/
SELECT 
product_key,
product_name,
category,
subcategory,
cost,
DATEDIFF(MONTH,MIN(order_date),MAX(order_date)) AS lifespan,
MAX(order_date) AS last_sale_date,
COUNT(DISTINCT order_number) AS total_orders,
COUNT(DISTINCT customer_key) AS total_customers,
SUM(quantity) AS total_quantity,
SUM(sales_amount) AS total_sales,
ROUND(AVG(CAST(sales_amount AS FLOAT)/NULLIF(quantity,0)),1) AS avg_selling_price
FROM Base_query
GROUP BY 
	product_key,
	product_name,
	category,
	subcategory,
	cost) 
/*--------------------------------------------------------------------------------
Final Query : Combines all product results into one output
---------------------------------------------------------------------------------*/
SELECT  
	product_key,
	product_name,
	category,
	subcategory,
	cost,
	last_sale_date,
	DATEDIFF(MONTH,last_sale_date,GETDATE()) AS recnecy_in_months,
	CASE 
		WHEN total_sales > 50000 THEN 'Highperfomer'
		WHEN total_sales >=10000 THEN 'Mid-range'
		ELSE 'Low perfomer'
	END AS product_segment,
	lifespan,
	total_orders,
	total_customers,
	total_quantity,
	total_sales,
	avg_selling_price,
	-- Average Order Revenue (AOR)
	CASE
		WHEN total_orders = 0 THEN 0 
		ELSE total_sales/total_orders
	END AS avg_order_revenue,
	-- Average monthly revenue
	CASE
		WHEN lifespan =0 THEN total_sales
		ELSE total_sales/lifespan
	END AS avg_monthly_revenue

FROM product_aggregation;

SELECT * from  gold.report_products;