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

ALTER TABLE stock_transactions
MODIFY COLUMN Transaction_ID VARCHAR(20),
MODIFY COLUMN Transaction_Type VARCHAR(10),
MODIFY COLUMN Out_Reason VARCHAR(50),
MODIFY COLUMN Part_ID VARCHAR(20),
MODIFY COLUMN Vendor_ID VARCHAR(10);

/* ("TEXT" datatype is meant for long, unstructured text (like descriptions, comments).
Columns like IDs, types, and reasons are short, structured data and thus "VARCHAR" makes more sense.
Also "VARCHAR" is faster for searches, comparisons, and joins.) */

ALTER TABLE spare_parts
MODIFY COLUMN Part_ID VARCHAR(10) NOT NULL,
MODIFY COLUMN Part_Name VARCHAR(100) NOT NULL,
MODIFY COLUMN Category VARCHAR(20) NOT NULL,
MODIFY COLUMN Unit_Cost DECIMAL(10,2) NOT NULL,
ADD CONSTRAINT pk_part PRIMARY KEY (Part_ID);

ALTER TABLE vendors 
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



