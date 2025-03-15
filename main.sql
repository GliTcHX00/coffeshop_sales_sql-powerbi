SELECT * from coffee_sales

DESCRIBE coffee_sales

--* TOTAL SALES
SELECT ROUND(SUM(unit_price * transaction_qty), 2) Total_sales
from coffee_sales
WHERE MONTH(transaction_date) = 5 -- may


SELECT MONTHNAME(transaction_date) MONTH, 
    ROUND(SUM(unit_price * transaction_qty), 2) Total_sales 
from coffee_sales
GROUP BY 1
ORDER BY 2 DESC


--* TOTAL SALES KPI - MOM DIFFERENCE AND MOM GROWTH
SELECT 
    MONTH(transaction_date) month,
    ROUND(SUM(unit_price * transaction_qty), 2) Total_sales,
    ROUND((SUM(unit_price * transaction_qty) - LAG(SUM(unit_price * transaction_qty), 1)
    OVER (ORDER BY MONTH(transaction_date))) / LAG(SUM(unit_price * transaction_qty), 1)
    OVER (ORDER BY MONTH(transaction_date)) * 100, 2)
from coffee_sales
WHERE 
    MONTH(transaction_date) in (4, 5) -- for April & May
GROUP BY 1


--* TOTAL ORDERS
SELECT COUNT(transaction_id), 
    MONTH(transaction_date)
from coffee_sales
GROUP BY(2)
ORDER BY 1 DESC


--* TOTAL ORDERS KPI - MOM DIFFERENCE AND MOM GROWTH
SELECT * from 
(
    SELECT 
        MONTH(transaction_date) month,
        COUNT(transaction_id) total_orders,
        LAG(COUNT(transaction_id), 1) OVER(ORDER BY MONTH(transaction_date)) last_month_orders,
        ROUND((COUNT(transaction_id) - LAG(COUNT(transaction_id), 1) OVER(ORDER BY MONTH(transaction_date)))
        / LAG(COUNT(transaction_id), 1) OVER(ORDER BY MONTH(transaction_date)) * 100, 2) as `%`
    from 
        coffee_sales
    -- WHERE 
    --     MONTH(transaction_date) in (4, 5)
    GROUP BY 
        MONTH(transaction_date)
) as t1
where `%` is not NULL


--* TOTAL QUANTITY SOLD
SELECT SUM(transaction_qty), 
    MONTH(transaction_date) 
from coffee_sales
GROUP BY 2


--* TOTAL QUANTITY SOLD KPI - MOM DIFFERENCE AND MOM GROWTH
SELECT * from 
(
    SELECT 
        MONTH(transaction_date) month,
        SUM(transaction_qty) total_Qty_sold,
        LAG(SUM(transaction_qty), 1) OVER(ORDER BY MONTH(transaction_date)) last_month_Qty_sold,
        ROUND((SUM(transaction_qty) - LAG(SUM(transaction_qty), 1) OVER(ORDER BY MONTH(transaction_date)))
        / LAG(SUM(transaction_qty), 1) OVER(ORDER BY MONTH(transaction_date)) * 100, 2) as `%`
    from 
        coffee_sales
    -- WHERE 
    --     MONTH(transaction_date) in (4, 5)
    GROUP BY 
        MONTH(transaction_date)
) as t1
where `%` is not NULL


--* CALENDAR TABLE – DAILY SALES, QUANTITY and TOTAL ORDERS
SELECT 
    CONCAT(ROUND(SUM(transaction_qty * unit_price) / 1000, 2), 'K') total_sales,
    CONCAT(ROUND(SUM(transaction_qty) / 1000, 2), 'K') total_Qty_sold,
    CONCAT(ROUND(COUNT(transaction_id) / 1000, 2), 'K') total_orders
from coffee_sales
WHERE 
    transaction_date = '2023-05-18'





--*** SALES BY WEEKDAY / WEEKEND:
--* Weekends => Sun & Sat - 1 & 7
--* Weekdays => Mon - Fri
SELECT
    CASE 
        WHEN DAYOFWEEK(transaction_date) IN (1,7) THEN 'Weekends'
        ELSE 'Weekdays'
    END as day_type,
    CONCAT(ROUND(SUM(transaction_qty * unit_price) / 1000, 2), 'K') total_sales
from coffee_sales
WHERE MONTH(transaction_date) = 5
GROUP BY 1


--* TOTAL SALES for each store location by month
SELECT
    store_location,
    MONTH(transaction_date),
    CONCAT(ROUND(SUM(transaction_qty * unit_price) / 1000, 2), 'K') total_sales
from coffee_sales
GROUP BY 2,1
ORDER BY 3 DESC


--------------

ALTER Table coffee_sales
ADD COLUMN total_sales FLOAT;

UPDATE coffee_sales 
SET total_sales = transaction_qty * unit_price;

SELECT * from coffee_sales

--------------


--* SALES TREND OVER PERIOD
SELECT 
    ROUND(AVG(sum_total_sales), 2)
from 
    (
        SELECT 
            SUM(total_sales) AS sum_total_sales
        from coffee_sales
        WHERE MONTH(transaction_date) = 5
        GROUP BY transaction_date
    ) as t1


--* DAILY SALES for may month
--- Sales for each DAY
SELECT
    DAY(transaction_date) Day_of_month, 
    ROUND(SUM(unit_price * transaction_qty), 2)
from coffee_sales
WHERE MONTH(transaction_date) = 5
GROUP BY 1
ORDER BY 1


--* COMPARING DAILY SALES WITH AVERAGE SALES – 
--* IF GREATER THAN “ABOVE AVERAGE” and LESSER THAN “BELOW AVERAGE”
SELECT 
    day_of_month,
    CASE 
        WHEN total_sales > avg_sales THEN 'Above Average'
        WHEN total_sales < avg_sales THEN 'Below Average'
        ELSE 'Equal to Average'
    END AS sales_status,
    total_sales
FROM (
    SELECT 
        DAY(transaction_date) AS day_of_month,
        SUM(unit_price * transaction_qty) AS total_sales,
        AVG(SUM(unit_price * transaction_qty)) OVER () AS avg_sales
    FROM 
        coffee_sales
    WHERE 
        MONTH(transaction_date) = 5  -- Filter for May
    GROUP BY 1
) AS sales_data
ORDER BY 1;


--* Top 10 Categories by sales
SELECT
    CONCAT(ROUND(SUM(total_sales) / 1000, 2), 'K') total_sales,
    product_category
from coffee_sales
GROUP BY 2
ORDER BY (SUM(total_sales)) DESC
LIMIT 10


--* TOP 3 Categories by sales for each month
SELECT * FROM (
    SELECT
        CONCAT(ROUND(SUM(total_sales) / 1000, 2), 'K') AS total_sales,
        product_category,
        MONTH(transaction_date) AS sales_month,
        RANK() OVER (PARTITION BY MONTH(transaction_date) ORDER BY SUM(total_sales) DESC) AS sales_rank
    FROM coffee_sales
    GROUP BY sales_month, product_category
    ORDER BY sales_month, sales_rank
) as t1
WHERE sales_rank <= 3


--* Top 10 Products by sales
SELECT
    CONCAT(ROUND(SUM(total_sales) / 1000, 2), 'K') total_sales,
    product_type
from coffee_sales
GROUP BY 2
ORDER BY (SUM(total_sales)) DESC
LIMIT 10



--* Sales Analysis by Days and hours
SELECT
    CONCAT(ROUND(SUM(total_sales) / 1000, 2), 'K') total_sales,
    SUM(transaction_qty) Total_Qty_sold,
    COUNT(*) Total_orders,
    HOUR(transaction_time) hour
from coffee_sales
WHERE  
    MONTH(transaction_date) = 5 -- MAY
    AND DAYOFWEEK(transaction_date) = 2 -- Monday
GROUP BY 4
ORDER BY (SUM(total_sales)) DESC


SELECT
    CONCAT(ROUND(SUM(total_sales) / 1000, 2), 'K') total_sales,
    DAYNAME(transaction_date) DAY
from coffee_sales
GROUP BY 2
ORDER BY (SUM(total_sales)) DESC