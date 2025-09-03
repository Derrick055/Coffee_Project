SELECT * FROM sales

-------- REPORTS & DATA ANALYSIS----------------
--Q1 HOW MANY PEOPLE IN EACH CITY ARE ESTIMATED TO CONSUME COFFEE, GIVEN THAT 25% OF THE POPULATION DOES
SELECT * FROM city;
SELECT * FROM customers;
SELECT * FROM products;
SELECT * FROM sales

SELECT
    c.city_name,
	CAST(SUM(c.population)* 0.25/1000000 AS DECIMAL(10,2)) AS coffee_consumers_in_millions
FROM city c
GROUP BY 1
ORDER BY 2 DESC


-- Q2 WHAT IS THE TOTAL REVENUE GENERATED FROM COFFEE SALES ACROSS ALL CITIES IN THE LAST QUARTER OF 2023
SELECT 
     ci.city_name,
	 COUNT(c.customer ) AS total_revenue
FROM sales s
JOIN customers c
ON s.customer_id = c.customer_id
JOIN city ci
ON ci.city_id = c.city_id
WHERE 
    EXTRACT(YEAR FROM sale_date) = 2023
AND
    EXTRACT(QUARTER FROM sale_date) = 4
GROUP BY 1
ORDER BY 2 DESC

-- Q3 HOW MANY UNIT OF EACH COFFEE PRODUCT HAVE BEEN SOLD
SELECT 
     p.product_name,
	 COUNT(s.sale_id)
FROM products p
JOIN sales s
ON p.product_id = s.product_id
GROUP BY 1 
ORDER BY 2 DESC

--Q4 FIND THE AVERAGE SALES AMOUNT PER CUSTOMER IN EACH CITY
SELECT
     ci.city_name,
	 SUM(s.total) AS total_revenue,
	 COUNT(DISTINCT s.customer_id) AS total_customers,
	 SUM(s.total)/ COUNT(DISTINCT s.customer_id)  AS avg_
FROM sales s
JOIN customers c
ON s.customer_id = c.customer_id
JOIN city ci
ON c.city_id = ci.city_id
GROUP BY 1
ORDER BY 2 DESC

-- Q5 PROVIDE LIST OF CITIES ALONG WITH THEIR POPULATION AND ESTIMATED COFFEE CONSUMERS
---list of cities, population, estimated consumers

SELECT
     city_name as city_name,
	 population AS population,
	 ROUND
	 (SUM(population) * 0.25/1000000,2) AS consumers_in_millions
FROM city 



--Q6 WHAT ARE THE TOP 3 SELLING PRODUCTS IN EACH CITY BASED ON SALES VOLUME?
-- top 3 sp, each city,based on sv

SELECT * FROM
(SELECT 
    p.product_name,
	ci.city_name,
	COUNT(sale_id),
	DENSE_RANK() OVER(PARTITION BY city_name ORDER BY COUNT(sale_id) DESC ) AS ranks
FROM products p
JOIN sales s
ON s.product_id = p.product_id
JOIN customers c
ON c.customer_id = s.customer_id
JOIN city ci
ON ci.city_id = c.city_id
GROUP BY 1,2) AS T1
WHERE ranks <=3


--Q7 HOW MANY UNIQUE CUSTOMERS ARE THERE IN EACH CITY WHO HAVE PURCHASED COFFEE PRODUCTS

SELECT
	ci.city_name,
	COUNT(DISTINCT(c.customer_name)) AS distinct_customers
FROM customers c
JOIN city ci
ON c.city_id = ci.city_id
JOIN sales s
ON s.customer_id = c.customer_id
JOIN products p
ON p.product_id = s.product_id
GROUP BY 1
ORDER BY 2 DESC
 
-- Q8 FIND EACH CITY AND THE AVERAGE SALES PER CUSTOMER AND AVG RENT PER CUSTOMER
WITH city_table
AS
(SELECT 
     ci.city_name,
	 SUM(s.total) AS total_revenue,
     COUNT(DISTINCT c.customer_id) AS total_cx,
	 SUM(s.total) / COUNT(DISTINCT c.customer_id) AS avg_sales_per_cust
FROM sales s
JOIN customers c
ON s.customer_id = s.customer_id
JOIN city ci
ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC
),

city_rent 
AS 
(SELECT
    city_name,
	estimated_rent
FROM city
) 

SELECT 
     cr.city_name,
	 cr.estimated_rent,
	 ct.total_cx,
	 ct.avg_sales_per_cust,
	 CAST((cr.estimated_rent/ct.total_cx) AS DECIMAL(10,2)) AS avg_rent_per_cust
FROM city_rent cr
JOIN city_table ct
ON cr.city_name = ct.city_name
	 
--Q9 Calculate the percentage growth or decline in sales over difference time period (monthly) by each city
WITH monthly_sales
AS
(	SELECT 
		ci.city_name,
		EXTRACT(MONTH FROM s.sale_date) AS Month,
		EXTRACT(YEAR FROM s.sale_date) AS Year,
		SUM(s.total) AS total_sales
	FROM sales s
	JOIN customers c
	ON s.customer_id = s.customer_id
	JOIN city ci
	ON ci.city_id = c.city_id
	GROUP BY 1,2,3
	ORDER BY 1,3,2
),
growth_ratio
AS
(    SELECT
	     city_name,
		 Month,
		 Year,
		 total_sales AS cr_month_sales,
		 LAG(total_sales, 1) OVER(PARTITION BY city_name ORDER BY Year, Month) AS last_month_sales
	 FROM monthly_sales
)

SELECT 
    city_name,
	Month,
	Year,
	last_month_sales,
	CAST(
	(cr_month_sales - last_month_sales)/last_month_sales * 100 AS DECIMAL (10,2)) AS growth_pct
FROM growth_ratio

-- Q10 identify the top 3 cities based highest sales, return city name, total sales, total rent, total customers, estimated coffee consumers
WITH city_table
AS
(SELECT 
     ci.city_name,
	 SUM(s.total) AS total_revenue,
     COUNT(DISTINCT c.customer_id) AS total_cx,
	 SUM(s.total) / COUNT(DISTINCT c.customer_id) AS avg_sales_per_cust
FROM sales s
JOIN customers c
ON s.customer_id = s.customer_id
JOIN city ci
ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC
),

city_rent 
AS 
(SELECT
    city_name,
	estimated_rent,
	CAST((population * 0.25/1000000) AS DECIMAL(10,2))AS estimated_coffee_consumers
FROM city
) 

SELECT 
     cr.city_name,
	 total_revenue,
	 cr.estimated_rent,
	 ct.total_cx,
	 estimated_coffee_consumers,
	 ct.avg_sales_per_cust,
	 CAST((cr.estimated_rent/ct.total_cx) AS DECIMAL(10,2)) AS avg_rent_per_cust
FROM city_rent cr
JOIN city_table ct
ON cr.city_name = ct.city_name
ORDER BY 2 DESC
LIMIT 3









