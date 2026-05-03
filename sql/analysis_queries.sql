-- DATA EXPLORATION & VALIDATION
SELECT * FROM swiggy_project.dim_date;
SELECT COUNT(*) FROM swiggy_project.dim_date;

SELECT * FROM swiggy_project.dim_dish;
SELECT COUNT(*) FROM swiggy_project.dim_dish;

SELECT * FROM swiggy_project.dim_location;
SELECT COUNT(*) FROM swiggy_project.dim_location;

SELECT * FROM swiggy_project.dim_restaurant;
SELECT COUNT(*) FROM swiggy_project.dim_restaurant;

SELECT * FROM swiggy_project.fact_orders;
SELECT COUNT(*) FROM swiggy_project.fact_orders;

-- Adding a new column with proper date type
ALTER TABLE swiggy_project.dim_date
ADD order_date_new DATE;

-- Adding data into new column which has created
UPDATE swiggy_project.dim_date
SET order_date_new = TRY_CONVERT(DATE, order_date, 5);

-- veryfying
SELECT * FROM swiggy_project.dim_date
where order_date_new IS NULL;


-- BUSINESS INSIGHTS
-- 1. What are the overall business KPIs?
SELECT
    ROUND(SUM(CAST(price AS DECIMAL(18,2))), 2) AS total_sales,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(CAST(price AS DECIMAL(18,2))) / NULLIF(COUNT(DISTINCT order_id), 0), 2) AS avg_order_value,
    ROUND(AVG(CAST(rating AS DECIMAL(10,2))), 2) AS avg_rating,
    SUM(rating_count) AS total_rating_count
FROM swiggy_project.fact_orders;

-- 2. Which month generated the highest sales?
SELECT
    DATENAME(MONTH, TRY_CONVERT(DATE, dd.order_date, 5)) AS month_name,
    MONTH(TRY_CONVERT(DATE, dd.order_date, 5)) AS month_number,
    ROUND(SUM(CAST(f.price AS DECIMAL(18,2))), 2) AS total_sales,
    COUNT(DISTINCT f.order_id) AS total_orders
FROM swiggy_project.fact_orders f
JOIN swiggy_project.dim_date dd
    ON f.date_id = dd.date_id
GROUP BY
    DATENAME(MONTH, TRY_CONVERT(DATE, dd.order_date, 5)),
    MONTH(TRY_CONVERT(DATE, dd.order_date, 5))
ORDER BY total_sales DESC;

-- 3. Which day of the week performs best?
SELECT
    DATENAME(WEEKDAY, TRY_CONVERT(DATE, dd.order_date, 5)) AS day_name,
    ROUND(SUM(CAST(f.price AS DECIMAL(18,2))), 2) AS total_sales,
    COUNT(DISTINCT f.order_id) AS total_orders
FROM swiggy_project.fact_orders f
JOIN swiggy_project.dim_date dd
    ON f.date_id = dd.date_id
GROUP BY DATENAME(WEEKDAY, TRY_CONVERT(DATE, dd.order_date, 5))
ORDER BY total_sales DESC;

-- 4. Which restaurants generate the most revenue?
SELECT TOP 10
    r.restaurant_name,
    ROUND(SUM(CAST(f.price AS DECIMAL(18,2))), 2) AS total_sales,
    COUNT(DISTINCT f.order_id) AS total_orders,
    ROUND(AVG(CAST(f.rating AS DECIMAL(10,2))), 2) AS avg_rating
FROM swiggy_project.fact_orders f
JOIN swiggy_project.dim_restaurant r
    ON f.restaurant_id = r.restaurant_id
GROUP BY r.restaurant_name
ORDER BY total_sales DESC;

-- 5. Which states contribute the highest sales?
SELECT TOP 10
    l.state,
    ROUND(SUM(CAST(f.price AS DECIMAL(18,2))), 2) AS total_sales,
    COUNT(DISTINCT f.order_id) AS total_orders
FROM swiggy_project.fact_orders f
JOIN swiggy_project.dim_location l
    ON f.location_id = l.location_id
GROUP BY l.state
ORDER BY total_sales DESC;

-- 6. Which cities have the highest order volume?
SELECT TOP 10
    l.city,
    l.state,
    COUNT(DISTINCT f.order_id) AS total_orders,
    ROUND(SUM(CAST(f.price AS DECIMAL(18,2))), 2) AS total_sales
FROM swiggy_project.fact_orders f
JOIN swiggy_project.dim_location l
    ON f.location_id = l.location_id
GROUP BY l.city, l.state
ORDER BY total_orders DESC;

-- 7. Which food categories perform best?
SELECT
    d.category,
    ROUND(SUM(CAST(f.price AS DECIMAL(18,2))), 2) AS total_sales,
    COUNT(DISTINCT f.order_id) AS total_orders,
    ROUND(AVG(CAST(f.rating AS DECIMAL(10,2))), 2) AS avg_rating
FROM swiggy_project.fact_orders f
JOIN swiggy_project.dim_dish d
    ON f.food_id = d.dish_id
GROUP BY d.category
ORDER BY total_sales DESC;

-- 8. What are the top-selling dishes?
SELECT TOP 10
    d.dish_name,
    d.category,
    ROUND(SUM(CAST(f.price AS DECIMAL(18,2))), 2) AS total_sales,
    COUNT(DISTINCT f.order_id) AS total_orders
FROM swiggy_project.fact_orders f
JOIN swiggy_project.dim_dish d
    ON f.food_id = d.dish_id
GROUP BY d.dish_name, d.category
ORDER BY total_sales DESC;

-- 9. Which restaurants have high sales but low ratings?
SELECT TOP 10
    r.restaurant_name,
    ROUND(SUM(CAST(f.price AS DECIMAL(18,2))), 2) AS total_sales,
    COUNT(DISTINCT f.order_id) AS total_orders,
    ROUND(AVG(CAST(f.rating AS DECIMAL(10,2))), 2) AS avg_rating
FROM swiggy_project.fact_orders f
JOIN swiggy_project.dim_restaurant r
    ON f.restaurant_id = r.restaurant_id
GROUP BY r.restaurant_name
HAVING COUNT(DISTINCT f.order_id) >= 100
ORDER BY total_sales DESC, avg_rating ASC;

-- 10. Which locations have the best average order value?
SELECT TOP 10
    l.state,
    l.city,
    l.location,
    ROUND(SUM(CAST(f.price AS DECIMAL(18,2))) / NULLIF(COUNT(DISTINCT f.order_id), 0), 2) AS avg_order_value,
    COUNT(DISTINCT f.order_id) AS total_orders
FROM swiggy_project.fact_orders f
JOIN swiggy_project.dim_location l
    ON f.location_id = l.location_id
GROUP BY l.state, l.city, l.location
HAVING COUNT(DISTINCT f.order_id) >= 50
ORDER BY avg_order_value DESC;

-- 11. What is the monthly sales growth trend?
WITH monthly_sales AS (
    SELECT
        YEAR(TRY_CONVERT(DATE, dd.order_date, 5)) AS order_year,
        MONTH(TRY_CONVERT(DATE, dd.order_date, 5)) AS order_month,
        ROUND(SUM(CAST(f.price AS DECIMAL(18,2))), 2) AS total_sales
    FROM swiggy_project.fact_orders f
    JOIN swiggy_project.dim_date dd
        ON f.date_id = dd.date_id
    GROUP BY
        YEAR(TRY_CONVERT(DATE, dd.order_date, 5)),
        MONTH(TRY_CONVERT(DATE, dd.order_date, 5))
)
SELECT
    order_year,
    order_month,
    total_sales,
    LAG(total_sales) OVER (ORDER BY order_year, order_month) AS previous_month_sales,
    ROUND(
        ((total_sales - LAG(total_sales) OVER (ORDER BY order_year, order_month))
        / NULLIF(LAG(total_sales) OVER (ORDER BY order_year, order_month), 0)) * 100,
    2) AS growth_percentage
FROM monthly_sales
ORDER BY order_year, order_month;

-- 12. Which restaurant-category combinations are strongest?
SELECT TOP 10
    r.restaurant_name,
    d.category,
    ROUND(SUM(CAST(f.price AS DECIMAL(18,2))), 2) AS total_sales,
    COUNT(DISTINCT f.order_id) AS total_orders,
    ROUND(AVG(CAST(f.rating AS DECIMAL(10,2))), 2) AS avg_rating
FROM swiggy_project.fact_orders f
JOIN swiggy_project.dim_restaurant r
    ON f.restaurant_id = r.restaurant_id
JOIN swiggy_project.dim_dish d
    ON f.food_id = d.dish_id
GROUP BY r.restaurant_name, d.category
ORDER BY total_sales DESC;

