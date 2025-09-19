-- Moday Cofee Data Analysis

SELECT * FROM city;
SELECT * FROM products;
SELECT * FROM customers;
SELECT * FROM sales;

-- Reports & Analysis

-- Q.1
-- Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?

SELECT
	city_name,
	ROUND((population * 0.25)/100000, 2) as cofee_consumers_in_lakh,
	city_rank
FROM city
ORDER BY 2 DESC;

-- Q.2
-- Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

SELECT
	ci.city_name,
	SUM(s.total) as revenue	
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
WHERE 
	EXTRACT(YEAR FROM s.sale_date) = 2023
	AND
	EXTRACT(quarter FROM s.sale_date) = 4
GROUP BY 1
ORDER BY 2 DESC;

-- Q.3
-- Sales Count for Each Product
-- How many units of each coffee product have been sold?

SELECT
	p.product_name,
	COUNT(s.sale_id) as total_order
FROM products as p
LEFT JOIN sales as s
ON s.product_id = p.product_id
GROUP BY 1
ORDER BY 2 DESC

-- Q.4
-- Average Sales Amount per City
-- What is the average sales amount per customer in each city?

-- Each city & total sales
-- Each city & total distinct no. of customers

SELECT
	ci.city_name,
	SUM(s.total) as revenue,	
	COUNT(DISTINCT s.customer_id) as total_cust,
	ROUND(SUM(s.total)::numeric / COUNT(DISTINCT s.customer_id)::numeric, 2) as avg_sale_per_cust
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 4 DESC;

-- Q.5
--City Population and Coffee Consumers
--Provide a list of cities along with their populations and estimated coffee consumers.

SELECT 
	ci.city_name,
	ci.population,
	ROUND((ci.population * 0.25) / 100000, 2) as coffee_consumer_in_lakh,
	COUNT(DISTINCT c.customer_id) as unique_cust
FROM
	city as ci
	LEFT JOIN customers as c
	ON c.city_id = ci.city_id
	GROUP BY 1,2
	ORDER BY 3 DESC

-- Q.6
-- Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?

SELECT *
FROM
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
	GROUP BY 1,2
	-- ORDER BY 1,3 DESC
	) as t1	
WHERE rank <= 3

-- Q.7
-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?

SELECT 
	ci.city_name,
	COUNT(DISTINCT c.customer_id) as unique_cust
FROM
	city as ci
	LEFT JOIN customers as c
	ON c.city_id = ci.city_id
	JOIN sales as s
	ON s.customer_id = c.customer_id
	WHERE s.product_id <= 14
	GROUP BY 1

-- Q.8
-- Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer

WITH cte AS
(
	SELECT
		ci.city_name,
		ci.estimated_rent,
		SUM(s.total) as revenue,
		COUNT(DISTINCT s.customer_id) as total_cust
	FROM sales as s
	JOIN customers as c
	ON s.customer_id = c.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1,2
)

SELECT
	city_name,
	total_cust,
	ROUND(estimated_rent::numeric / total_cust, 2) as avg_rent_per_cust,
	ROUND(revenue::numeric / total_cust, 2) as avg_sale_per_cust
FROM cte
ORDER BY 4 DESC

-- Q.9
-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly).

WITH cte1 AS
(
	SELECT 
		ci.city_name,
		EXTRACT(MONTH FROM sale_date) as month,
		EXTRACT(YEAR FROM sale_date) as year,
		SUM(s.total) as total_sale	
	FROM sales as s
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1,2,3
	ORDER BY 1,3,2
),
cte2 AS
(
	SELECT 
		city_name,
		month,
		year,
		total_sale as current_month_sale,
		LAG(total_sale,1) OVER(PARTITION BY city_name ORDER BY year, month) last_month_sale
	FROM cte1
)

SELECT
	city_name,
	month,
	year,
	current_month_sale,
	last_month_sale,
	ROUND((current_month_sale - last_month_sale)::numeric / last_month_sale::numeric * 100, 2) as growth_rate
FROM cte2
WHERE last_month_sale IS NOT NULL

-- Q.10
-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer

WITH cte AS	
(
	SELECT
			ci.city_name,
			ci.estimated_rent,
			ci.population,
			SUM(s.total) as total_sale,
			COUNT(DISTINCT s.customer_id) as total_cust,
			ROUND((ci.population * 0.25) / 100000, 2) as estim_coffee_consumer_in_lakh
		FROM sales as s
		JOIN customers as c
		ON s.customer_id = c.customer_id
		JOIN city as ci
		ON ci.city_id = c.city_id
		GROUP BY 1,2,3
		ORDER BY 4 DESC
)
SELECT
	city_name,
	estimated_rent,
	total_sale,
	total_cust,
	estim_coffee_consumer_in_lakh,
	ROUND(estimated_rent::numeric / total_cust, 2) as avg_rent_per_cust,
	ROUND(total_sale::numeric / total_cust, 2) as avg_sale_per_cust
FROM cte
ORDER BY 3 DESC	

/*
-- Recomendation
City 1: Pune
	1. Avg rent per customer is very less,
	2. highest total revenue,
	3. age sale per customer is also high

City 2: Dehli
	1. Highest estimated coffee consumer which is 77.50 lakh
	2. total customer also very good, 68 (highest is 69)
	3. avg rent per customer 330 (under 500)

City 3: Jaipur
	1. Highest customer no which is 69
	2. avg rent per customer is very less
	3. avg sale per customer is better, 11.6k (highest is 24.2k)