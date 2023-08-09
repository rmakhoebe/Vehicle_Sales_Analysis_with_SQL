--Inspecting Data
SELECT*
FROM VehicleSales

--Checking unique values
SELECT DISTINCT status FROM VehicleSales
SELECT DISTINCT productline FROM VehicleSales
SELECT DISTINCT year_id FROM VehicleSales
SELECT DISTINCT dealsize FROM VehicleSales
SELECT DISTINCT Country FROM VehicleSales
SELECT DISTINCT territory FROM VehicleSales

--ANALYSIS
--Group by sales of product line
SELECT PRODUCTLINE, SUM(SALES) AS TotalSales
FROM VehicleSales
GROUP BY PRODUCTLINE
ORDER BY 2 DESC

--Year they made the most sales
SELECT year_id, SUM(SALES) AS TotalSales
FROM VehicleSales
GROUP BY year_id
ORDER BY 2 DESC
--Note from above query: 2005 TotalSales were extremely low so I figured it is because they operated for only 5months that year using the following script
--SELECT DISTINCT MONTH_ID FROM VehicleSales
--Where year_id = 2005

--Total sales by DealSize
SELECT dealsize, SUM(SALES) AS TotalSales
FROM VehicleSales
GROUP BY DEALSIZE
ORDER BY 2 DESC

--Best month for sales in a specific year
SELECT MONTH_ID, YEAR_ID, SUM(SALES) AS TotalSales
FROM VehicleSales
GROUP BY MONTH_ID, YEAR_ID
ORDER BY 3 DESC
--OR
SELECT MONTH_ID, SUM(SALES) AS TotalSales
FROM VehicleSales
Where year_id = 2003
GROUP BY MONTH_ID
ORDER BY 2 DESC

--For 2003 and 2004, November seems to be the best selling month. Which productline sells the most?
SELECT PRODUCTLINE, SUM(SALES) AS TotalSales
FROM VehicleSales
Where MONTH_ID = 11 and YEAR_ID = 2004
GROUP BY PRODUCTLINE
ORDER BY 2 DESC

--Who is our best customer (this could be answered with RFM)
--SELECT  CUSTOMERNAME, SUM(SALES)
--FROm VehicleSales
--GROUP BY CUSTOMERNAME
--ORDER BY 2 DESC
DROP TABLE IF EXISTS #RFM;
WITH RFM AS (
Select
	CUSTOMERNAME,
	sum(sales) as MonetaryValue,
	avg(sales) as Avg_MonetaryValue,
	count(ordernumber) as Frequency,
	max(orderdate) as last_order_date,
	(select max(orderdate) from VehicleSales) as system_last_order,
	DATEDIFF(dd, max(orderdate),(select max(orderdate) from VehicleSales)) as Recency
FROM VehicleSales
GROUP BY CUSTOMERNAME
),
RFM_calc as
(
			SELECT *,
				NTILE(4) OVER(ORDER BY Recency DESC) as rfm_recency, --the closer the last_order_date is to the system_last_order date, the higher the rfm_recency
				NTILE(4) OVER(ORDER BY Frequency) as rfm_frequency, --the higher the frequency, the higher the rfm_frequency
				NTILE(4) OVER(ORDER BY MonetaryValue) as rfm_monetary --the higher the monetary value, the higher the rfm_monetary
			FROM RFM
)
SELECT *,  rfm_recency+ rfm_frequency +  rfm_monetary as rfm_cell, concat (rfm_recency, rfm_frequency ,  rfm_monetary) as rfm_cell_comb
into #RFM
FROM RFM_calc

SELECT*
FROM #RFM

SELECT CUSTOMERNAME, rfm_recency, rfm_frequency ,  rfm_monetary,
	CASE
		when rfm_cell_comb in (111,112,121,122,123,132,211,212,114,141) then 'lost customer' --lost customers
		when rfm_cell_comb in (133,134,143,244,334,343,344,144) then 'slipping away.' --big spenders who haven't purchased lately
		when rfm_cell_comb in (311,411,331) then 'new customer'
		when rfm_cell_comb in (222,223,233,322) then 'potential churners'
		when rfm_cell_comb in (323,333,321,422,332,432) then 'active customer' --customers who buy often but spend a little
		when rfm_cell_comb in (433,434,443,444) then 'loyal'
		ELSE 'average customer'
	END as RFM_segment
FROM #RFM
--OR
SELECT CUSTOMERNAME, rfm_recency, rfm_frequency ,  rfm_monetary,rfm_cell,
	CASE when rfm_cell >= 9 then 'High Value Customer'
		 when rfm_cell >= 6 then 'Average Customer'
		 when rfm_cell >= 3 then 'Low Value Customer'
	END as RFM_segment
FROM #RFM
ORDER BY rfm_cell

--What products are most often sold together? Results could be use when making promotions to determine which combinations of products customers have a higher chance of purchasing
select distinct ORDERNUMBER, stuff( --we use the stuff function to remove the first comma in the xml and that returns a string
			(select CONCAT(',',  PRODUCTCODE)
			from VehicleSales as t1
			where ORDERNUMBER in (
								select ordernumber
								from (
										select ordernumber, count(PRODUCTCODE) as CountofShipped
										from VehicleSales
										where status = 'shipped'
										GROUP BY ORDERNUMBER 
									) as Orders
								where CountofShipped = 2
								) and t1.ORDERNUMBER = t2.ORDERNUMBER
								for xml path('')) --After getting rows of productlines that are within the subquery 'Orders',
													--I appended the results into a single column by using xml path function
													--and separating each result with a comma.
			, 1, 1, '') as Products--this says, apply stuff function from first character as starting point,number of character
													--we want to change is character 1 and replace it with 'nothing'
FROM VehicleSales as t2
Order by 2 DESC

Select*
From VehicleSales

--Revenue By Country
SELECT COUNTRY, Sum(SALES) as TotalSales
From Vehiclesales
GROUP BY Country
ORDER BY 2 DESC