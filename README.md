 Indian Railways Inventory Management & Vendor Performance Analysis (SQL Project)

Overview:

This project demonstrates how SQL can be used to analyze and optimize inventory, vendor performance, and procurement operations for Indian Railways maintenance system.


Problem Statement (Inventory Management SQL Project):

In many organizations, inefficient inventory tracking leads to stockouts, overstocking, and poor vendor performance — directly affecting production and sales. The goal of this project is to analyze and optimize inventory data using SQL.

 	This project focuses on solving key business questions such as:
 	Which items are running low and need reordering?
 	How efficiently are vendors fulfilling purchase orders?
 	What are the monthly trends in stock inflow and outflow?


The dataset simulates spare parts, vendor details, and stock transactions — all designed to reflect realistic railway inventory workflows.

The analysis focuses on:

⦁	Monitoring stock inflow/outflow.
⦁	Calculating vendor on-time delivery performance.
⦁	Vendor rank on basis of their reliability.
⦁	Tracking monthly trends and identifying cost optimization opportunities.


Dataset Description:
 1. spare_parts :
 	Column		Description
 	Part_ID		Unique ID for each spare part
 	Part_Name	Name of the spare part
 	Category		Type (Mechancical,electrical,signalling etc.)
 	Unit_Cost		Cost per unit
 
2. Vendors :
 	Column		Description
 	Vendor_ID	Unique vendor code
 	Vendor_Name	Vendor firm name
 	Location		Vendor city
 	Contact_Number	Vendor contact (standardized 10-digit)

3. stock_transactions:
 	Column			Description
 	Transaction_ID		Unique transaction record
 	Transaction_Type		IN (purchase) or OUT (issue)
 	Part_ID			Foreign key to spare_parts
 	Vendor_ID		Foreign key to vendors
 	Quantity			Number of items purchased/issued
 	Purchase_Order_Date	Date of order placement
 	Promised_Date		Vendor’s committed delivery date
 	Transaction_Date		Actual delivery/issue date
 	Out_Reason		Reason for issuing stock (if OUT)



Data Cleaning & Preparation:
 	1. Checked for duplicates, error and proper column formats.
 	2. Converted text date columns to DATE format using STR_TO_DATE().
 	3. Standardized datatypes using ALTER TABLE.

Key Analytical Queries:

/* VARIOUS QUERIES USED FOR ANALYSINF VENFOR PERFORMANCE,CURRENT STOCK,
TOTAL COST PER PART PER YEAR, AVERAGE MONTHLY CONSUMPTION PER PART etc are as follows: */

UPDATE stock_transactions
SET Purchase_order_date = NULL
WHERE Purchase_order_date = '';

/* Note: Blanks or empty strings must be handled before converting a text column to DATE — either replace them with NULL or a valid date. Otherwise you will get error 1292 'Incorrect date value' and SQL will not allow you to convert text datatype to date datatype for your column. */


UPDATE stock_transactions
SET Promised_date = NULL
WHERE Promised_date = '';

SELECT Transaction_Date,
       STR_TO_DATE(Transaction_Date, '%d-%m-%Y')
FROM stock_transactions;

/*(Because right now the datatype is text for transaction_date,purchase_order_date and promised_date and MySQL expects the standard ISO format 'YYYY-MM-DD'
(e.g.'2023-08-27') when converting to a DATE type.) */


UPDATE stock_transactions
SET Purchase_order_date = STR_TO_DATE(Purchase_order_date, '%d-%m-%Y'),
    Promised_date       = STR_TO_DATE(Promised_date, '%d-%m-%Y')
    WHERE Transaction_type = "IN";

UPDATE stock_transactions
    SET transaction_date = STR_TO_DATE(transaction_date, '%d-%m-%Y');



ALTER TABLE stock_transactions
MODIFY COLUMN Purchase_order_date DATE,
MODIFY COLUMN Promised_date DATE,
Modify column Transaction_Date DATE;

-- (To convert Text datatype to Date datatype for columns representing dates.)

ALTER TABLE stock_transactions:
MODIFY COLUMN Transaction_ID VARCHAR(20),
MODIFY COLUMN Transaction_Type VARCHAR(10),
MODIFY COLUMN Out_Reason VARCHAR(50),
MODIFY COLUMN Part_ID VARCHAR(20),
MODIFY COLUMN Vendor_ID VARCHAR(10);

/* ("TEXT" datatype is meant for long, unstructured text (like descriptions, comments).
Columns like IDs, types, and reasons are short, structured data and thus "VARCHAR" makes more sense.
Also "VARCHAR" is faster for searches, comparisons, and joins.) */

ALTER TABLE spare_parts:
MODIFY COLUMN Part_ID VARCHAR(10) NOT NULL,
MODIFY COLUMN Part_Name VARCHAR(100) NOT NULL,
MODIFY COLUMN Category VARCHAR(20) NOT NULL,
MODIFY COLUMN Unit_Cost DECIMAL(10,2) NOT NULL,
ADD CONSTRAINT pk_part PRIMARY KEY (Part_ID);

ALTER TABLE vendors:
Modify column Vendor_id VARCHAR(5) NOT NULL,
MODIFY column Vendor_name Varchar(50) NOT NULL,
Modify column location Varchar(30) NOT NULL,
Modify column contact_number varchar(15)  NOT NULL,
Add constraint primary_key Primary key(vendor_id);



-- On time delivery % of each vendor:

SELECT
    Vendor_ID,
    COUNT(*) AS Total_Orders,
    SUM(CASE WHEN Promised_Date >= Transaction_Date THEN 1 ELSE 0 END) AS On_Time,
    SUM(CASE WHEN Promised_Date >= Transaction_Date THEN 1 ELSE 0 END)/COUNT(*)*100 AS OnTime_Percentage
FROM stock_transactions
WHERE Transaction_Type='IN'
GROUP BY Vendor_ID order by Vendor_ID;


-- Vendor rank on basis of their reliability:

with vendor_reliability as
 	(SELECT
    Vendor_ID,
    COUNT(*) AS Total_Orders,
    SUM(CASE WHEN Promised_Date >= Transaction_Date THEN 1 ELSE 0 END) AS On_Time,
    SUM(CASE WHEN Promised_Date >= Transaction_Date THEN 1 ELSE 0 END)/COUNT(*)*100 AS OnTime_Percentage
FROM stock_transactions
WHERE Transaction_Type='IN'
GROUP BY Vendor_ID order by Vendor_ID)
select Vendor_ID,Total_Orders, On_Time,OnTime_Percentage,
rank() over(order by OnTime_Percentage desc) as vendor_reliability_rank from vendor_reliability;



-- Total cost per part per year:

SELECT stock_transactions.Part_ID, year(transaction_date),
sum(Quantity*Unit_Cost) as Total_cost
FROM stock_transactions
JOIN spare_parts ON spare_parts.Part_ID = stock_transactions.Part_ID
where Transaction_Type = "IN"
GROUP BY Part_ID,year(transaction_date)
order by Part_ID, year(transaction_date) desc;

-- Count and Sum of Out transactions by Reason:
 select Out_Reason, count(*) as total_transaction_count, sum(Quantity) as Total_quantity
from  stock_transactions
where transaction_type  = "OUT"
group by out_reason order by total_transaction_count desc;


-- current stock per part :
select part_id,sum(
 	case when Transaction_Type = "in" then quantity else 0
    end) -
    sum(
    case when Transaction_Type = "out" then quantity else 0
    end) as Current_stock
 from stock_transactions
group by Part_ID
order by Part_ID;

 
-- Time based analysis with Monthly IN/OUT quantity per Part_id:
 
select part_id, date_format(transaction_date, "%Y-%m") as month,
sum(case when Transaction_Type = "IN" THEN Quantity ELSE 0 END) AS In_quantity,
sum(case when Transaction_Type = "OUT" THEN Quantity else 0 end) as Out_quantity
from stock_transactions
group by Part_ID,month order by Part_ID, month desc;

-- Vendor performance trend (monthly):

SELECT
    Vendor_ID, date_format(transaction_date, '%m-%Y') AS MONTH,
    SUM(CASE WHEN Promised_Date >= Transaction_Date THEN 1 ELSE 0 END) / COUNT(*) * 100 AS OnTime_Percentage
FROM stock_transactions
WHERE Transaction_Type='IN'
GROUP BY Vendor_ID,YEAR(Transaction_Date),MONTH(Transaction_Date)
ORDER BY Vendor_ID,YEAR(Transaction_Date) DESC, MONTH(Transaction_Date) DESC ;


-- Cost Optimization / Insights High-cost + low stock parts:

SELECT stock_transactions.Part_ID,
sum(CASE WHEN Transaction_Type = "IN" THEN Quantity*Unit_Cost ELSE 0 END) as total_cost,
sum(CASE when Transaction_Type = "IN" THEN Quantity ELSE 0 END) -
SUM(CASE WHEN Transaction_Type = "OUT" THEN quantity ELSE 0 END) as current_stock
from stock_transactions
left join spare_parts
on stock_transactions.Part_ID = spare_parts.Part_ID
group by stock_transactions.part_id
having current_stock <= 1000 -- low stock threshold
order by stock_transactions.Part_ID;

/* Predictive / Forecasting Prep
Average monthly consumption per part (helps in forecasting) */

With monthly_data as (select part_id, date_format(transaction_date, "%Y-%m")  as month,
 sum(case when transaction_type = "out" then quantity else 0 end) as monthly_out
 from stock_transactions group by Part_ID, month)
 select part_id, avg(monthly_out) from monthly_data
group by part_id order by part_id ;



Key Insights:

 	1. Identified vendors with on-time delivery accuracy between 50%–95%.

 	2.Found high-cost parts with low availability, indicating potential restocking priorities.

 	3.Monthly trend analysis provided inputs for forecasting spare part demand.


Tools & Technologies:

 	SQL (MySQL) – Data Cleaning, Joins, Aggregations, Window Functions

 	GitHub – Version control and documentation



📁 Project Structure
├── spare_parts.csv
├── vendors.csv
├── stock_transactions.csv
├── Inventory_Management.sql
└── Inventory_Management.md



Author: Aashish Rohila
LinkedIn/ AASHISH ROHILA
GitHub/ AASHISH ROHILA
