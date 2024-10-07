# Monday Coffee Expansion SQL Project

![Company Logo](https://github.com/datamugger/Monday-Coffee_Sales_Analysis_using_SQL/blob/main/1.png)

## Objective
The goal of this project is to analyze the sales data of Monday Coffee, a company that has been selling its products online since January 2023, and to recommend the top three major cities in India for opening new coffee shop locations based on consumer demand and sales performance.

## Key Questions
1. **Coffee Consumers Count**  
   How many people in each city are estimated to consume coffee, given that 25% of the population does?

2. **Total Revenue from Coffee Sales**  
   What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

3. **Sales Count for Each Product**  
   How many units of each coffee product have been sold?

4. **Average Sales Amount per City**  
   What is the average sales amount per customer in each city?

5. **City Population and Coffee Consumers**  
   Provide a list of cities along with their populations and estimated coffee consumers.

6. **Top Selling Products by City**  
   What are the top 3 selling products in each city based on sales volume?

7. **Customer Segmentation by City**  
   How many unique customers are there in each city who have purchased coffee products?

8. **Average Sale vs Rent**  
   Find each city and their average sale per customer and avg rent per customer

9. **Monthly Sales Growth**  
   Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly).

10. **Market Potential Analysis**  
    Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated  coffee consumer

## Data Analysis
 Q.1 **Coffee Consumers Count**<br>
 How many people in each city are estimated to consume coffee, given that 25% of the population does?

```sql
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
```

Q.2 **Total Revenue from Coffee Sales**<br>
What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

```sql
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
```

Q.3 **Sales Count for Each Product**<br>
How many units of each coffee product have been sold?

```sql
SELECT 
	p.product_name,
	COUNT(s.sale_id) as total_orders
FROM products as p
LEFT JOIN
sales as s
ON s.product_id = p.product_id
GROUP BY 1
ORDER BY 2 DESC
```

Q.4 **Average Sales Amount per City**<br>
What is the average sales amount per customer in each city?
```sql
SELECT 
	ci.city_name,
	SUM(s.total) as total_revenue,
	COUNT(DISTINCT s.customer_id) as total_customer, 
	ROUND(SUM(s.total)::numeric / COUNT(DISTINCT s.customer_id)::numeric, 2) as avg_sale_per_customer
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC
```

Q.5 **City Population and Coffee Consumers (25%)**<br>
Provide a list of cities along with their populations and estimated coffee consumers. Return city_name, total current cx, estimated coffee consumers (25%)

```sql
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
```

Q6 **Top Selling Products by City**<br>
What are the top 3 selling products in each city based on sales volume?

```sql
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
```

Q.7 **Customer Segmentation by City**<br>
How many unique customers are there in each city who have purchased coffee products?

```sql
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
```

Q.8 **Average Sale vs Rent**<br>
Find each city and their average sale per customer and avg rent per customer

```sql
WITH city_table
AS
(
	SELECT 
		ci.city_name,
		SUM(s.total) as total_revenue,
		COUNT(DISTINCT s.customer_id) as total_cx,
		ROUND( SUM(s.total)::numeric / COUNT(DISTINCT s.customer_id)::numeric, 2) as avg_sale_pr_cx
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
```

Q.9 **Monthly Sales Growth**<br>
Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly) by each city

```sql
WITH monthly_sales
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
)
, growth_ratio
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
	ROUND((cr_month_sale-last_month_sale)::numeric/last_month_sale::numeric * 100, 2) as growth_ratio
FROM growth_ratio;
```

Q.10 **Market Potential Analysis**<br>
Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer

```sql
WITH city_table AS (
	SELECT 
		ci.city_name,
		SUM(s.total) as total_revenue,
		COUNT(DISTINCT s.customer_id) as total_cx,
		ROUND(SUM(s.total)::numeric/ COUNT(DISTINCT s.customer_id)::numeric, 2) as avg_sale_pr_cx
	FROM sales as s
	JOIN customers as c
	ON s.customer_id = c.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
	ORDER BY 2 DESC
)
, city_rent AS (
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
	ROUND(cr.estimated_rent::numeric / ct.total_cx::numeric, 2) as avg_rent_per_cx
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 2 DESC;
```

## Recommendations
After analyzing the data, the recommended top three cities for new store openings are:

**Few Asssumptions**
1. Rent must be low (< 500)
2. Average sales should be good.
3. Coffee Customer in the city should be good.

**City 1: Pune**  
1. Average rent per customer is very low.  
2. Highest total revenue.  
3. Average sales per customer is also high.

**City 2: Delhi**  
1. Highest estimated coffee consumers at 7.7 million.  
2. Highest total number of customers, which is 68.  
3. Average rent per customer is 330 (still under 500).

**City 3: Jaipur**  
1. Highest number of customers, which is 69.  
2. Average rent per customer is very low at 156.  
3. Average sales per customer is better at 11.6k.

---
