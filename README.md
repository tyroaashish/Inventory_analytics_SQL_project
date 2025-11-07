####  **Indian Railways Inventory Management \& Vendor Performance Analysis (SQL Project)**



**Overview:**



This project demonstrates how SQL can be used to analyze and optimize inventory, vendor performance, and procurement operations for Indian Railways maintenance system.





Problem Statement (Inventory Management SQL Project):



In many organizations, inefficient inventory tracking leads to stockouts, overstocking, and poor vendor performance — directly affecting production and sales. The goal of this project is to analyze and optimize inventory data using SQL.



 	This project focuses on solving key business questions such as:

 	Which items are running low and need reordering?

 	How efficiently are vendors fulfilling purchase orders?

 	What are the monthly trends in stock inflow and outflow?





The dataset simulates spare parts, vendor details, and stock transactions — all designed to reflect realistic railway inventory workflows.



The analysis focuses on:



* Monitoring stock inflow/outflow.
* Calculating vendor on-time delivery performance.
* Vendor rank on basis of their reliability.
* Tracking monthly trends and identifying cost optimization opportunities.





Dataset Description:

 1. spare\_parts :

 	Column		Description

 	Part\_ID		Unique ID for each spare part

 	Part\_Name	Name of the spare part

 	Category		Type (Mechancical,electrical,signalling etc.)

 	Unit\_Cost		Cost per unit

 

2\. Vendors :

 	Column		Description

 	Vendor\_ID	Unique vendor code

 	Vendor\_Name	Vendor firm name

 	Location		Vendor city

 	Contact\_Number	Vendor contact (standardized 10-digit)



3\. stock\_transactions:

 	Column			Description

 	Transaction\_ID		Unique transaction record

 	Transaction\_Type		IN (purchase) or OUT (issue)

 	Part\_ID			Foreign key to spare\_parts

 	Vendor\_ID		Foreign key to vendors

 	Quantity			Number of items purchased/issued

 	Purchase\_Order\_Date	Date of order placement

 	Promised\_Date		Vendor’s committed delivery date

 	Transaction\_Date		Actual delivery/issue date

 	Out\_Reason		Reason for issuing stock (if OUT)







Data Cleaning \& Preparation:

 	1. Checked for duplicates, error and proper column formats.

 	2. Converted text date columns to DATE format using STR\_TO\_DATE().

 	3. Standardized datatypes using ALTER TABLE.



Key Analytical Queries:



/\* VARIOUS QUERIES USED FOR ANALYSINF VENFOR PERFORMANCE,CURRENT STOCK,

TOTAL COST PER PART PER YEAR, AVERAGE MONTHLY CONSUMPTION PER PART etc are as follows: \*/



UPDATE stock\_transactions

SET Purchase\_order\_date = NULL

WHERE Purchase\_order\_date = '';



/\* Note: Blanks or empty strings must be handled before converting a text column to DATE — either replace them with NULL or a valid date. Otherwise you will get error 1292 'Incorrect date value' and SQL will not allow you to convert text datatype to date datatype for your column. \*/





UPDATE stock\_transactions

SET Promised\_date = NULL

WHERE Promised\_date = '';



SELECT Transaction\_Date,

       STR\_TO\_DATE(Transaction\_Date, '%d-%m-%Y')

FROM stock\_transactions;



/\*(Because right now the datatype is text for transaction\_date,purchase\_order\_date and promised\_date and MySQL expects the standard ISO format 'YYYY-MM-DD'

(e.g.'2023-08-27') when converting to a DATE type.) \*/





UPDATE stock\_transactions

SET Purchase\_order\_date = STR\_TO\_DATE(Purchase\_order\_date, '%d-%m-%Y'),

    Promised\_date       = STR\_TO\_DATE(Promised\_date, '%d-%m-%Y')

    WHERE Transaction\_type = "IN";



UPDATE stock\_transactions

    SET transaction\_date = STR\_TO\_DATE(transaction\_date, '%d-%m-%Y');







ALTER TABLE stock\_transactions

MODIFY COLUMN Purchase\_order\_date DATE,

MODIFY COLUMN Promised\_date DATE,

Modify column Transaction\_Date DATE;



-- (To convert Text datatype to Date datatype for columns representing dates.)



ALTER TABLE stock\_transactions

MODIFY COLUMN Transaction\_ID VARCHAR(20),

MODIFY COLUMN Transaction\_Type VARCHAR(10),

MODIFY COLUMN Out\_Reason VARCHAR(50),

MODIFY COLUMN Part\_ID VARCHAR(20),

MODIFY COLUMN Vendor\_ID VARCHAR(10);



/\* ("TEXT" datatype is meant for long, unstructured text (like descriptions, comments).

Columns like IDs, types, and reasons are short, structured data and thus "VARCHAR" makes more sense.

Also "VARCHAR" is faster for searches, comparisons, and joins.) \*/



ALTER TABLE spare\_parts

MODIFY COLUMN Part\_ID VARCHAR(10) NOT NULL,

MODIFY COLUMN Part\_Name VARCHAR(100) NOT NULL,

MODIFY COLUMN Category VARCHAR(20) NOT NULL,

MODIFY COLUMN Unit\_Cost DECIMAL(10,2) NOT NULL,

ADD CONSTRAINT pk\_part PRIMARY KEY (Part\_ID);



ALTER TABLE vendors

Modify column Vendor\_id VARCHAR(5) NOT NULL,

MODIFY column Vendor\_name Varchar(50) NOT NULL,

Modify column location Varchar(30) NOT NULL,

Modify column contact\_number varchar(15)  NOT NULL,

Add constraint primary\_key Primary key(vendor\_id);







-- On time delivery % of each vendor:



SELECT

    Vendor\_ID,

    COUNT(\*) AS Total\_Orders,

    SUM(CASE WHEN Promised\_Date >= Transaction\_Date THEN 1 ELSE 0 END) AS On\_Time,

    SUM(CASE WHEN Promised\_Date >= Transaction\_Date THEN 1 ELSE 0 END)/COUNT(\*)\*100 AS OnTime\_Percentage

FROM stock\_transactions

WHERE Transaction\_Type='IN'

GROUP BY Vendor\_ID order by Vendor\_ID;





-- Vendor rank on basis of their reliability:



with vendor\_reliability as

 	(SELECT

    Vendor\_ID,

    COUNT(\*) AS Total\_Orders,

    SUM(CASE WHEN Promised\_Date >= Transaction\_Date THEN 1 ELSE 0 END) AS On\_Time,

    SUM(CASE WHEN Promised\_Date >= Transaction\_Date THEN 1 ELSE 0 END)/COUNT(\*)\*100 AS OnTime\_Percentage

FROM stock\_transactions

WHERE Transaction\_Type='IN'

GROUP BY Vendor\_ID order by Vendor\_ID)

select Vendor\_ID,Total\_Orders, On\_Time,OnTime\_Percentage,

rank() over(order by OnTime\_Percentage desc) as vendor\_reliability\_rank from vendor\_reliability;







-- Total cost per part per year:



SELECT stock\_transactions.Part\_ID, year(transaction\_date),

sum(Quantity\*Unit\_Cost) as Total\_cost

FROM stock\_transactions

JOIN spare\_parts ON spare\_parts.Part\_ID = stock\_transactions.Part\_ID

where Transaction\_Type = "IN"

GROUP BY Part\_ID,year(transaction\_date)

order by Part\_ID, year(transaction\_date) desc;



-- Count and Sum of Out transactions by Reason:

 select Out\_Reason, count(\*) as total\_transaction\_count, sum(Quantity) as Total\_quantity

from  stock\_transactions

where transaction\_type  = "OUT"

group by out\_reason order by total\_transaction\_count desc;





-- current stock per part :

select part\_id,sum(

 	case when Transaction\_Type = "in" then quantity else 0

    end) -

    sum(

    case when Transaction\_Type = "out" then quantity else 0

    end) as Current\_stock

 from stock\_transactions

group by Part\_ID

order by Part\_ID;



 

-- Time based analysis with Monthly IN/OUT quantity per Part\_id:

 

select part\_id, date\_format(transaction\_date, "%Y-%m") as month,

sum(case when Transaction\_Type = "IN" THEN Quantity ELSE 0 END) AS In\_quantity,

sum(case when Transaction\_Type = "OUT" THEN Quantity else 0 end) as Out\_quantity

from stock\_transactions

group by Part\_ID,month order by Part\_ID, month desc;



-- Vendor performance trend (monthly):



SELECT

    Vendor\_ID, date\_format(transaction\_date, '%m-%Y') AS MONTH,

    SUM(CASE WHEN Promised\_Date >= Transaction\_Date THEN 1 ELSE 0 END) / COUNT(\*) \* 100 AS OnTime\_Percentage

FROM stock\_transactions

WHERE Transaction\_Type='IN'

GROUP BY Vendor\_ID,YEAR(Transaction\_Date),MONTH(Transaction\_Date)

ORDER BY Vendor\_ID,YEAR(Transaction\_Date) DESC, MONTH(Transaction\_Date) DESC ;





-- Cost Optimization / Insights High-cost + low stock parts:



SELECT stock\_transactions.Part\_ID,

sum(CASE WHEN Transaction\_Type = "IN" THEN Quantity\*Unit\_Cost ELSE 0 END) as total\_cost,

sum(CASE when Transaction\_Type = "IN" THEN Quantity ELSE 0 END) -

SUM(CASE WHEN Transaction\_Type = "OUT" THEN quantity ELSE 0 END) as current\_stock

from stock\_transactions

left join spare\_parts

on stock\_transactions.Part\_ID = spare\_parts.Part\_ID

group by stock\_transactions.part\_id

having current\_stock <= 1000 -- low stock threshold

order by stock\_transactions.Part\_ID;



/\* Predictive / Forecasting Prep

Average monthly consumption per part (helps in forecasting) \*/



With monthly\_data as (select part\_id, date\_format(transaction\_date, "%Y-%m")  as month,

 sum(case when transaction\_type = "out" then quantity else 0 end) as monthly\_out

 from stock\_transactions group by Part\_ID, month)

 select part\_id, avg(monthly\_out) from monthly\_data

group by part\_id order by part\_id ;







Key Insights:



 	1. Identified vendors with on-time delivery accuracy between 50%–95%.



 	2.Found high-cost parts with low availability, indicating potential restocking priorities.



 	3.Monthly trend analysis provided inputs for forecasting spare part demand.





Tools \& Technologies:



 	SQL (MySQL) – Data Cleaning, Joins, Aggregations, Window Functions



 	GitHub – Version control and documentation







📁 Project Structure

├── spare\_parts.csv

├── vendors.csv

├── stock\_transactions.csv

├── Inventory\_Management.sql

└── Inventory\_Management.md







Author: Aashish Rohila

[LinkedIn/ AASHISH ROHILA](www.linkedin.com/in/aashish0292)

[GitHub/ AASHISH ROHILA](https://github.com/tyroaashish)

