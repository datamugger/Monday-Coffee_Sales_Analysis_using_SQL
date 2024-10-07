----------------------------------------- Monday Coffee Data Analysis -----------------------------------------

-- Data Exploration

SELECT * FROM city;
SELECT * FROM products;
SELECT * FROM customers;
SELECT * FROM sales;


----------------------------------------- Business Problem & their Solutions ----------------------------------


-- Q.1 Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?


SELECT * FROM city;

SELECT 
	city_name, (population * 0.25) coffee_population, city_rank
FROM city
order by 2 DESC;

-- final answer
SELECT 
	city_name,
	ROUND((population * 0.25)/1000000 , 2) as coffee_consumers_in_millions,
	city_rank
FROM city
ORDER BY 2 DESC


-- Q.2
-- Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

SELECT * FROM sales;
SELECT * FROM customers;
SELECT * FROM city;


SELECT 
	SUM(total) as total_revenue
FROM sales
WHERE 
	EXTRACT(YEAR FROM sale_date)  = 2023
	AND
	EXTRACT(quarter FROM sale_date) = 4


-- final answer
SELECT 
	ci.city_name,
	SUM(s.total) as total_revenue
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
WHERE 
	EXTRACT(YEAR FROM s.sale_date)  = 2023
	AND
	EXTRACT(quarter FROM s.sale_date) = 4
GROUP BY 1
ORDER BY 2 DESC


-- Q.3
-- Sales Count for Each Product
-- How many units of each coffee product have been sold?

SELECT * FROM products;
SELECT * FROM sales;

-- Notice, we want count meaning total orders of each product, not their revenues
-- we should keep Products to the LEFT during join, as all the products may not get ordered
-- and we want to know about it.

SELECT 
	p.product_name,
	COUNT(s.sale_id) as total_orders
FROM products as p
LEFT JOIN
sales as s
ON s.product_id = p.product_id
GROUP BY 1
ORDER BY 2 DESC


-- Q.4
-- Average Sales Amount per City
-- What is the average sales amount per customer in each city?

-- city and total sale
-- no of customers in each of these city, is required to find the average sales

SELECT * FROM city;
SELECT * FROM customers;
SELECT * FROM sales;

SELECT 
	ci.city_name,
	SUM(s.total) as total_revenue,
	COUNT(DISTINCT s.customer_id) as total_customer, -- total distinct customer city wise who ordered coffee
	ROUND(
			SUM(s.total)::numeric/
				COUNT(DISTINCT s.customer_id)::numeric
			,2) as avg_sale_per_customer
	
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC


-- sQ.5
-- City Population and Coffee Consumers (25%)
-- Provide a list of cities along with their populations and estimated coffee consumers.
-- return city_name, total current cx, estimated coffee consumers (25%)

SELECT * FROM city;
SELECT * FROM products;
SELECT * FROM customers;
SELECT * FROM sales;

WITH city_table as (
	SELECT 
		city_name, ROUND(population/1000000 , 2) as population,
		ROUND((population * 0.25)/1000000, 2) as coffee_consumers
	FROM city
),
customers_table AS (
	SELECT 
		ci.city_name,
		COUNT(DISTINCT c.customer_id) as total_customers
	FROM sales as s
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
)
SELECT 
	customers_table.city_name,
	city_table.population as population_in_millions,
	city_table.coffee_consumers as coffee_consumer_in_millions,
	customers_table.total_customers
FROM city_table
JOIN  customers_table
ON city_table.city_name = customers_table.city_name


-- Q6
-- Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?

SELECT * FROM sales;
SELECT * FROM products;
SELECT * FROM customers;
SELECT * FROM city;


SELECT * 
FROM -- table
(
	SELECT 
		ci.city_name,
		p.product_name,
		COUNT(s.sale_id) as total_orders,
		DENSE_RANK() OVER(PARTITION BY ci.city_name ORDER BY COUNT(s.sale_id) DESC) as rank
	FROM sales as s
	JOIN products as p
	ON s.product_id = p.product_id
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1, 2
	-- ORDER BY 1, 3 DESC
) as t1
WHERE rank <= 3


-- Q.7
-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?

SELECT * FROM city;
SELECT * FROM customers;
SELECT * FROM sales;
SELECT * FROM products; -- 28 unique products, but we only want products from 1 to 14


SELECT 
	ci.city_name,
	COUNT(DISTINCT customer_id) as total_customer
FROM city as ci
JOIN customers as c
ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC; -- this will give us unique customers in each city, but we have to ensure that
                 -- these customers must have purchased some products from Monday Coffee shop
				 -- For, that, we should JOIN with 'sales' table as well and use it's customer_id column 


SELECT ci.city_name, c.customer_id, s.sale_id,s.customer_id, s.product_id
FROM city as ci
LEFT JOIN customers as c
ON c.city_id = ci.city_id
LEFT JOIN sales as s
ON s.customer_id = c.customer_id;


SELECT ci.city_name, count(distinct c.customer_id), count(s.sale_id), count(distinct s.customer_id)
, count(distinct product_id)
FROM city as ci
LEFT JOIN customers as c
ON c.city_id = ci.city_id
LEFT JOIN sales as s
ON s.customer_id = c.customer_id
group by ci.city_name;

-- final answer for product b/w 1 and 14
SELECT 
	ci.city_name,
	COUNT(DISTINCT c.customer_id) as unique_cx
FROM city as ci
LEFT JOIN customers as c
ON c.city_id = ci.city_id
JOIN sales as s
ON s.customer_id = c.customer_id
WHERE 
	s.product_id IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14)
GROUP BY 1;


-- Q.8
-- Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer

SELECT * FROM sales;
SELECT * FROM customers;
SELECT * FROM city;


WITH city_table
AS
(
	SELECT 
		ci.city_name,
		SUM(s.total) as total_revenue,
		COUNT(DISTINCT s.customer_id) as total_cx,
		ROUND( SUM(s.total)::numeric /
				COUNT(DISTINCT s.customer_id)::numeric
			 , 2) as avg_sale_pr_cx
		
	FROM sales as s
	JOIN customers as c
	ON s.customer_id = c.customer_id
	JOIN city as ci
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
	ct.avg_sale_pr_cx,
	ROUND( cr.estimated_rent::numeric / ct.total_cx::numeric, 2) as avg_rent_per_cx
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 4 DESC;


-- Q.9
-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)
-- by each city

SELECT * FROM city;
SELECT * FROM products;
SELECT * FROM customers;
SELECT * FROM sales;


WITH
monthly_sales
AS
(
	SELECT 
		ci.city_name,
		EXTRACT(MONTH FROM sale_date) as month,
		EXTRACT(YEAR FROM sale_date) as YEAR,
		SUM(s.total) as total_sale
	FROM sales as s
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1, 2, 3
	ORDER BY 1, 3, 2
),
growth_ratio
AS
(
		SELECT
			city_name,
			month,
			year,
			total_sale as cr_month_sale,
			LAG(total_sale, 1) OVER(PARTITION BY city_name ORDER BY year, month) as last_month_sale
		FROM monthly_sales
)

SELECT
	city_name,
	month,
	year,
	cr_month_sale,
	last_month_sale,
	ROUND(
		(cr_month_sale-last_month_sale)::numeric/last_month_sale::numeric * 100
		, 2
		) as growth_ratio

FROM growth_ratio;


-- Q.10
-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, 
-- total customers, estimated coffee consumer

SELECT * FROM city;
SELECT * FROM products; 
SELECT * FROM customers;
SELECT * FROM sales;

WITH city_table
AS
(
	SELECT 
		ci.city_name,
		SUM(s.total) as total_revenue,
		COUNT(DISTINCT s.customer_id) as total_cx,
		ROUND(
				SUM(s.total)::numeric/
					COUNT(DISTINCT s.customer_id)::numeric
				,2) as avg_sale_pr_cx
		
	FROM sales as s
	JOIN customers as c
	ON s.customer_id = c.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
	ORDER BY 2 DESC
),
city_rent
AS
(
	SELECT 
		city_name, 
		estimated_rent,
		ROUND((population * 0.25)/1000000, 3) as estimated_coffee_consumer_in_millions
	FROM city
)
SELECT 
	cr.city_name,
	total_revenue,
	cr.estimated_rent as total_rent,
	ct.total_cx,
	estimated_coffee_consumer_in_millions,
	ct.avg_sale_pr_cx,
	ROUND(
		cr.estimated_rent::numeric/
									ct.total_cx::numeric
		, 2) as avg_rent_per_cx
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 2 DESC;

/*
-- Recomendation

-- Few Asssumptions
-- 1. Rent must be low (< 500)
-- 2. Average sales should be good.
-- 3. Coffee Customer in a city should be good.

City 1: Pune
	1.Average rent per customer is very low.
	2.Highest total revenue.
	3.Average sales per customer is also high.

City 2: Delhi
	1.Highest estimated coffee consumers at 7.7 million.
	2.Highest total number of customers, which is 68.
	3.Average rent per customer is 330 (still under 500).

City 3: Jaipur
	1.Highest number of customers, which is 69.
	2.Average rent per customer is very low at 156.
	3.Average sales per customer is better at 11.6k.