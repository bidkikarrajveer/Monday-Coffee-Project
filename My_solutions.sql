-- Monday Coffee -- Data Analysis

SELECT * FROM city;
SELECT * FROM products;
SELECT * FROM customers;
SELECT * FROM sales;

-- Reports & Data Analysis 

-- Q1. Coffee consumers count 
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?

SELECT 
	city_name,
	ROUND((population * 0.25)/1000000, 2) as coffee_consumers_in_millions,
	city_rank
FROM city
ORDER BY 2 DESC


-- Q2. Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

SELECT 
	SUM(total) as total_revenue
FROM sales
WHERE 
	EXTRACT(YEAR FROM sale_date)=2023
	AND
	EXTRACT(quarter FROM sale_date)=4

SELECT
	ci.city_name,
	SUM(total) as total_revenue
FROM sales as s
JOIN customers as c
ON s.customer_id=c.customer_id
JOIN city as ci
ON ci.city_id=c.city_id
WHERE 
	EXTRACT(YEAR FROM s.sale_date)=2023
	AND
	EXTRACT(quarter FROM s.sale_date)=4
GROUP BY 1
ORDER BY 2 DESC


-- Q3. Sales Count for Each Product
-- How many units of each coffee product have been sold?

SELECT 
	p.product_name,
	COUNT(s.sale_id) as total_orders
FROM products as p
LEFT JOIN 
sales as s
ON s.product_id=p.product_id
GROUP BY 1
ORDER BY 2 DESC


-- Q4. Average Sales Amount per City
-- What is the average sales amount per customer in each city?
-- city and total sale
-- no customer in each of these cities
SELECT
	ci.city_name,
	SUM(s.total) as total_revenue,
	COUNT(DISTINCT s.customer_id) as total_customer,
	ROUND(SUM(s.total)::numeric / COUNT(DISTINCT s.customer_id)::numeric, 2) as avg_sale_per_customer
FROM sales as s
JOIN customers as c
ON s.customer_id=c.customer_id
JOIN city as ci
ON ci.city_id=c.city_id
GROUP BY 1
ORDER BY 2 DESC


-- Q5. City Population and Coffee Consumers (25%)
-- Provide a list of cities along with their populations and estimated coffee consumers.
-- return city_name, total current customers, estimated coffee consumers (25%)

SELECT
		ci.city_name,
		COUNT(DISTINCT c.customer_id) as unique_customer,
		ROUND(SUM((population * 0.25) / 1000000), 2) as coffee_consumers_in_millions
	FROM city as ci
	LEFT JOIN customers as c 
	ON c.city_id=ci.city_id
	GROUP BY 1
	ORDER BY 2 DESC


-- Q6. Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?

SELECT * 
FROM --table
(
	SELECT 
		ci.city_name,
		p.product_name,
		COUNT(s.sale_id) as total_orders,
		DENSE_RANK() OVER(PARTITION BY ci.city_name ORDER BY COUNT(s.sale_id) DESC) as rank
	FROM sales as s
	JOIN products as p
	ON s.product_id=p.product_id
	JOIN customers as c
	ON c.customer_id=s.customer_id
	JOIN city as ci
	ON ci.city_id=ci.city_id
	GROUP BY 1, 2 
	--ORDER BY 1, 3 DESC
)as t1
WHERE rank <= 3 


-- Q7. Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?

SELECT
	ci.city_name,
	COUNT(DISTINCT c.customer_id) as unique_customer
FROM city as ci
LEFT JOIN customers as c 	
ON c.city_id=ci.city_id 
JOIN sales as s
ON s.customer_id=c.customer_id
JOIN products as p
ON p.product_id=s.product_id
WHERE 
	s.product_id IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14)
GROUP BY 1


-- Q8. Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer

--conclusions

WITH city_table
AS
( 
	SELECT
		ci.city_name,
		COUNT(DISTINCT s.customer_id) as total_customer,
		ROUND(SUM(s.total)::numeric / COUNT(DISTINCT s.customer_id)::numeric, 2) as avg_sale_per_customer
FROM sales as s
JOIN customers as c
ON s.customer_id=c.customer_id
JOIN city as ci
ON ci.city_id=c.city_id
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
	ct.total_customer,
	ct.avg_sale_per_customer,
	ROUND(cr.estimated_rent::numeric / ct.total_customer::numeric, 2) as avg_rent_per_customer
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name=ct.city_name
ORDER BY 4 DESC


-- city and total rent/total customer


-- Q9. Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly).

WITH
monthly_sales
AS
(SELECT 
	ci.city_name,
	EXTRACT(MONTH FROM sale_date) as month,
	EXTRACT(YEAR FROM sale_date) as year,
	SUM(s.total) as total_sale
FROM sales as s 
JOIN customers as c 
ON c.customer_id = s.customer_id
JOIN city as ci
ON ci.city_id=c.city_id
GROUP BY 1, 2, 3
ORDER BY 1, 2, 3
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
		 (cr_month_sale - last_month_sale)::numeric / last_month_sale::numeric * 100
		  ,2) as growth_ratio
FROM growth_ratio
WHERE 
	last_month_sale IS NOT NULL
		 
-- Q10. Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer