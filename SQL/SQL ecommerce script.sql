---Data Summary
SELECT 
    COUNT(*) AS total_rows,
    COUNT(DISTINCT InvoiceNo) AS unique_invoices,
    COUNT(DISTINCT CustomerID) AS unique_customers,
    COUNT(DISTINCT StockCode) AS unique_products,
    MIN(Quantity) AS min_qty,
    MAX(Quantity) AS max_qty,
    ROUND(AVG(Quantity), 2) AS avg_qty,
    MIN(UnitPrice) AS min_price,
    MAX(UnitPrice) AS max_price,
    ROUND(AVG(UnitPrice), 2) AS avg_price,
    SUM(Quantity * UnitPrice) AS total_revenue
FROM ecommerce;    
    
total_rows|unique_invoices|unique_customers|unique_products|min_qty|max_qty|avg_qty|min_price|max_price|avg_price|total_revenue|
----------+---------------+----------------+---------------+-------+-------+-------+---------+---------+---------+-------------+
    541909|          25900|            4372|           4070| -80995|  80995|   9.55|-11062.06|  38970.0|     4.61|  9747747.934|    
    

---Check Nulls, zero and empties   
SELECT 
 	'invoice_no' AS column_name,
 	COUNT(*) AS total_rows,
 	SUM(CASE WHEN InvoiceNo IS NULL THEN 1 ELSE 0 END) AS nulls,
 	SUM(CASE WHEN InvoiceNo = 0 THEN 1 ELSE 0 END) AS zero,
 	0 AS empties
FROM ecommerce e 
UNION ALL  
SELECT 
 	'stock_code',
 	COUNT(*) AS total_rows,
 	SUM(CASE WHEN StockCode IS NULL THEN 1 ELSE 0 END) AS nulls,
 	0 AS zero,
 	SUM(CASE WHEN StockCode = '' THEN 1 ELSE 0 END) AS empties
FROM ecommerce e 
UNION ALL  
SELECT 
 	'description',
 	COUNT(*) AS total_rows,
 	SUM(CASE WHEN Description IS NULL THEN 1 ELSE 0 END) AS nulls,
 	0 AS zero,
 	SUM(CASE WHEN Description = '' THEN 1 ELSE 0 END) AS empties
FROM ecommerce e 
UNION ALL  
SELECT 
 	'quantity' AS column_name,
 	COUNT(*) AS total_rows,
 	SUM(CASE WHEN Quantity IS NULL THEN 1 ELSE 0 END) AS nulls,
 	SUM(CASE WHEN Quantity = 0 THEN 1 ELSE 0 END) AS zero,
 	0 AS empties
FROM ecommerce e
UNION ALL  
SELECT 
 	'invoice_date',
 	COUNT(*) AS total_rows,
 	SUM(CASE WHEN InvoiceDate IS NULL THEN 1 ELSE 0 END) AS nulls,
 	0 AS zero,
 	SUM(CASE WHEN InvoiceDate = '' THEN 1 ELSE 0 END) AS empties
FROM ecommerce e 
UNION ALL  
SELECT 
 	'unit_price' AS column_name,
 	COUNT(*) AS total_rows,
 	SUM(CASE WHEN UnitPrice IS NULL THEN 1 ELSE 0 END) AS nulls,
 	SUM(CASE WHEN UnitPrice = 0.0 THEN 1 ELSE 0 END) AS zero,
 	0 AS empties
FROM ecommerce e
UNION ALL 
SELECT 
 	'customer_id' AS column_name,
 	COUNT(*) AS total_rows,
 	SUM(CASE WHEN CustomerID IS NULL THEN 1 ELSE 0 END) AS nulls,
 	SUM(CASE WHEN CustomerID = 0 THEN 1 ELSE 0 END) AS zero,
 	0 AS empties
FROM ecommerce e
UNION ALL  
SELECT 
 	'country',
 	COUNT(*) AS total_rows,
 	SUM(CASE WHEN Country IS NULL THEN 1 ELSE 0 END) AS nulls,
 	0 AS zero,
 	SUM(CASE WHEN Country = '' THEN 1 ELSE 0 END) AS empties
FROM ecommerce e;
	
column_name |total_rows|nulls |zero|empties|
------------+----------+------+----+-------+
invoice_no  |    541909|     0|   0|      0|
stock_code  |    541909|     0|   0|      0|
description |    541909|  1454|   0|      0|
quantity    |    541909|     0|   0|      0|
invoice_date|    541909|     0|   0|      0|
unit_price  |    541909|     0|2515|      0|
customer_id |    541909|135080|   0|      0|
country     |    541909|     0|   0|      0|	


--- Check Duplicate
SELECT 
	InvoiceNo,
	COUNT(*) as sum_duplicate,
	ROUND(((COUNT(*)*100.0)/(SELECT COUNT(*) 
		FROM ecommerce)),2) AS "% Duplicate"
FROM ecommerce 
GROUP BY InvoiceNo
HAVING COUNT (*) > 1
ORDER BY sum_duplicate DESC 
LIMIT 10;

InvoiceNo|sum_duplicate|% Duplicate|
---------+-------------+-----------+
   573585|         1114|       0.21|
   581219|          749|       0.14|
   581492|          731|       0.13|
   580729|          721|       0.13|
   558475|          705|       0.13|
   579777|          687|       0.13|
   581217|          676|       0.12|
   537434|          675|       0.12|
   580730|          662|       0.12|
   538071|          652|       0.12|


WITH id_customer AS (
SELECT   
	CustomerID ,
	COUNT(*) as sum_duplicate
FROM ecommerce 
GROUP BY CustomerID 
having COUNT(*) > 1
ORDER BY sum_duplicate DESC 
LIMIT 10
)
SELECT 
	CustomerID,
	sum_duplicate,
	ROUND((sum_duplicate*100.0)/(SELECT COUNT(*) 
		FROM ecommerce e),2) AS "% Duplicate"
FROM id_customer 
GROUP BY CustomerID, sum_duplicate 
ORDER BY "% Duplicate" DESC ;

CustomerID|sum_duplicate|% Duplicate|
----------+-------------+-----------+
          |       135080|      24.93|
     17841|         7983|       1.47|
     14911|         5903|       1.09|
     14096|         5128|       0.95|
     12748|         4642|       0.86|
     14606|         2782|       0.51|
     15311|         2491|       0.46|
     14646|         2085|       0.38|
     13089|         1857|       0.34|
     13263|         1677|       0.31|


--- Create TABLE SalesChan to modify data
---	CustomerID has problem

CREATE TABLE SalesChan AS
SELECT *,
	CASE
		WHEN Country = 'Hong Kong' THEN 'RetailStore'
		WHEN Country = 'Unspecified' THEN 'GuestCheckout'
		WHEN CustomerID IS NULL OR CustomerID = '' THEN 'Anonymous'
			ELSE 'OnlineRegistered'
	END AS SalesChannel
FROM ecommerce;

SELECT 
    SalesChannel,
    COUNT(*) AS transaction_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM SalesChan), 2) AS percent,
    ROUND(SUM(Quantity * UnitPrice),2) AS total_revenue
FROM SalesChan
GROUP BY SalesChannel 
ORDER BY total_revenue DESC;

SalesChannel    |transaction_count|percent|total_revenue|
----------------+-----------------+-------+-------------+
OnlineRegistered|           406585|  75.03|   8297398.74|
Anonymous       |           134590|  24.84|   1435482.36|
RetailStore     |              288|   0.05|     10117.04|
GuestCheckout   |              446|   0.08|      4749.79|



--Check Date and Transformation
SELECT 
    InvoiceDate,
    printf(
        '%04d-%02d-%02d',
        -- TAHUN: Ambil karakter antara slash kedua sampai spasi
        CAST(substr(InvoiceDate, 
                    instr(substr(InvoiceDate, instr(InvoiceDate, '/') + 1), '/') + instr(InvoiceDate, '/') + 1, 
                    4) AS INTEGER),
        -- BULAN: Ambil karakter sebelum slash pertama
        CAST(substr(InvoiceDate, 1, instr(InvoiceDate, '/') - 1) AS INTEGER),
        -- HARI: Ambil karakter di antara dua slash
        CAST(substr(InvoiceDate, 
                    instr(InvoiceDate, '/') + 1, 
                    instr(substr(InvoiceDate, instr(InvoiceDate, '/') + 1), '/') - 1) AS INTEGER)
    ) AS clean_date
FROM ecommerce
LIMIT 10;

InvoiceDate     |clean_date|
----------------+----------+
12/17/2010 14:41|2010-12-17|
12/17/2010 14:41|2010-12-17|
12/17/2010 14:41|2010-12-17|
12/17/2010 14:41|2010-12-17|     



ALTER TABLE SalesChan ADD COLUMN invoice_date DATE;

UPDATE SalesChan
SET invoice_date = printf(
    '%04d-%02d-%02d',
    -- YEAR
    CAST(substr(InvoiceDate, 
                instr(substr(InvoiceDate, instr(InvoiceDate, '/') + 1), '/') + instr(InvoiceDate, '/') + 1, 
                4) AS INTEGER),
    -- MONTH
    CAST(substr(InvoiceDate, 1, instr(InvoiceDate, '/') - 1) AS INTEGER),
    -- DAY
    CAST(substr(InvoiceDate, 
                instr(InvoiceDate, '/') + 1, 
                instr(substr(InvoiceDate, instr(InvoiceDate, '/') + 1), '/') - 1) AS INTEGER)
);



-
--- Create table ecommerce -final
CREATE TABLE ecommerce_final AS  
SELECT
	InvoiceNo				AS invoice_no,
	StockCode				AS stock_code,
	Description				AS description,
	Quantity				AS quantity,
	invoice_date,
	UnitPrice				AS unit_price,
	CustomerID				AS cutomer_id,
	Country					AS country,
	SalesChannel 			AS sales_channel
FROM SalesChan;


PRAGMA table_info(ecommerce);

cid|name       |type   |notnull|dflt_value|pk|
---+-----------+-------+-------+----------+--+
  0|InvoiceNo  |INTEGER|      0|          | 0|
  1|StockCode  |TEXT   |      0|          | 0|
  2|Description|TEXT   |      0|          | 0|
  3|Quantity   |INTEGER|      0|          | 0|
  4|InvoiceDate|TEXT   |      0|          | 0|
  5|UnitPrice  |REAL   |      0|          | 0|
  6|CustomerID |INTEGER|      0|          | 0|
  7|Country    |TEXT   |      0|          | 0|
  
  
PRAGMA table_info(ecommerce_final);

cid|name         |type|notnull|dflt_value|pk|
---+-------------+----+-------+----------+--+
  0|invoice_no   |INT |      0|          | 0|
  1|stock_code   |TEXT|      0|          | 0|
  2|description  |TEXT|      0|          | 0|
  3|quantity     |INT |      0|          | 0|
  4|invoice_date |NUM |      0|          | 0|
  5|unit_price   |REAL|      0|          | 0|
  6|cutomer_id   |INT |      0|          | 0|
  7|country      |TEXT|      0|          | 0|
  8|sales_channel|    |      0|          | 0|


---Sales by Country    
SELECT 
    Country,
    COUNT(DISTINCT CustomerID) AS customers,
    COUNT(DISTINCT InvoiceNo) AS transactions,
    ROUND(SUM(Quantity * UnitPrice), 2) AS total_sales,
    ROUND(100.0 * SUM(Quantity * UnitPrice) / SUM(SUM(Quantity * UnitPrice)) OVER (), 2) AS sales_percentage
FROM CleanedSales cs 
GROUP BY Country
ORDER BY total_sales DESC
LIMIT 10;

Country       |customers|transactions|total_sales|sales_percentage|
--------------+---------+------------+-----------+----------------+
United Kingdom|     3945|       22383|  8288238.7|           83.77|
Netherlands   |        9|         101|  284767.14|            2.88|
EIRE          |        3|         354|  271453.61|            2.74|
Germany       |       95|         598|  223925.65|            2.26|
France        |       87|         459|  206906.76|            2.09|
Australia     |        9|          69|  137077.27|            1.39|
Spain         |       30|         102|    57617.2|            0.58|
Switzerland   |       21|          74|   56385.35|            0.57|
Belgium       |       25|         119|   40910.96|            0.41|
Sweden        |        8|          46|   36595.91|            0.37|


---Monthly Trend
SELECT 
    strftime('%Y-%m', invoice_date) AS month,
    COUNT(DISTINCT invoice_no) AS transactions,
    ROUND(SUM(quantity * unit_price), 2) AS total_sales
FROM ecommerce_final
GROUP BY strftime('%Y-%m', invoice_date)
ORDER BY month
LIMIT 10;

month  |transactions|total_sales|
-------+------------+-----------+
2010-12|        1955|  751488.64|
2011-01|        1387|  565213.57|
2011-02|        1342|  502234.37|
2011-03|        1870|   694900.0|
2011-04|        1569|  501862.83|
2011-05|        2047|   739133.1|
2011-06|        1947|  735541.54|
2011-07|        1805|  696549.57|
2011-08|        1684|  688786.21|
2011-09|        2253|  1026428.9|


SELECT * FROM ecommerce_final ef 
limit 200;


---Check top 10 Best Selling Products
SELECT  
	country,
	description,
	SUM(unit_price*quantity) AS sales
FROM ecommerce_final ef 
WHERE country = 'United Kingdom'
GROUP BY country, description
ORDER BY sales DESC  
LIMIT 10;

country       |description                       |sales    |
--------------+----------------------------------+---------+
United Kingdom|DOTCOM POSTAGE                    |206245.48|
United Kingdom|REGENCY CAKESTAND 3 TIER          |134405.94|
United Kingdom|WHITE HANGING HEART T-LIGHT HOLDER| 93953.07|
United Kingdom|PARTY BUNTING                     | 92501.73|
United Kingdom|JUMBO BAG RED RETROSPOT           | 84516.44|
United Kingdom|PAPER CHAIN KIT 50'S CHRISTMAS    | 61888.19|
United Kingdom|ASSORTED COLOUR BIRD ORNAMENT     | 54662.15|
United Kingdom|CHILLI LIGHTS                     | 52986.86|
United Kingdom|PICNIC BASKET WICKER 60 PIECES    |  39619.5|
United Kingdom|BLACK RECORD COVER FRAME          |  39387.0|
    

    
    
    

    