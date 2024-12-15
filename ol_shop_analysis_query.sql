
-- Task 1
-- Goals: Show the product IDs and product names that have been ordered more than once! Sorted by product ID
-- Steps:
-- 1. Join the `products` table with the `sales` table using `product_id` to find orders associated with each product.
-- 2. Group the results by `product_id` and `product_name` to calculate the total number of orders (`COUNT(order_id)`) for each product.
-- 3. Use the `HAVING` clause to filter products with more than one order (`COUNT(order_id) > 1`).
-- 4. Sort the results by `product_id` in ascending order for clarity.

CREATE TEMPORARY TABLE product_ordered_1 AS (
    SELECT 
        p.product_id,                
        p.product_name,              
        COUNT(s.order_id) AS total_order 
    FROM
        products p
        LEFT JOIN sales s USING(product_id) 
    GROUP BY
        p.product_id,                
        p.product_name             
    HAVING
        COUNT(s.order_id) > 1        
    ORDER BY
        p.product_id             
);

-- Task 2
-- Goals: How many products have been ordered more than once?
-- Steps:
-- 1. Use the `COUNT(DISTINCT product_id)` function to count the unique product IDs from the `product_ordered_1` table.
-- 2. Use the temporary table `product_ordered_1` created in Question 1. This table contains products that have been ordered more than once.
-- 3. Return the result, which represents the total number of products ordered more than once.

SELECT 
    COUNT(DISTINCT product_id) AS products_ordered_more_than_once 
FROM 
    product_ordered_1;

-- Task 3
-- Goals: How many products have only been ordered once?
-- Steps:
-- 1. Create a Common Table Expression (CTE) named `product_ordered`:
--    - Join the `products` table with the `sales` table using `product_id`.
--    - Group by `product_id` to calculate the total number of orders (`COUNT(order_id)`) for each product.
-- 2. Filter the products that have only one order (`total_order = 1`).
-- 3. Use `COUNT(DISTINCT product_id)` to count the unique product IDs that meet the filter condition.
-- 4. Return the count as the total number of products ordered only once.

WITH product_ordered AS (
    SELECT 
        p.product_id,               
        p.product_name,             
        COUNT(s.order_id) AS total_order 
    FROM
        products p
        LEFT JOIN sales s USING(product_id) 
    GROUP BY
        p.product_id,              
        p.product_name            
)
SELECT
    COUNT(DISTINCT product_id) AS total_product_ordered_once -- Step 3: Count distinct product IDs with only one order
FROM 
    product_ordered
WHERE
    total_order = 1; 

-- Task 4
-- Goals: list of customers who have placed orders more than twice in a single month. Manager need customer name and their address to give the customer special discount
-- Steps:
-- 1. Create a Common Table Expression (CTE) named `special_customer`:
--    - Extract the month and year from `order_date` to identify orders placed in the same month.
--    - Count the number of orders (`COUNT(order_id)`) for each customer in a month.
--    - Filter customers with more than 2 orders in a single month using the `HAVING` clause.
--    - Group by `customer_id`, order month, and order year to calculate order counts per month.
-- 2. Join the `special_customer` CTE with the `customers` table to retrieve the customer name and address.
-- 3. Return the customer name and home address for eligible customers.

WITH special_customer AS (
    SELECT
        customer_id,
        EXTRACT(MONTH FROM order_date::date) AS order_month,
        EXTRACT(YEAR FROM order_date::date) AS order_year,
        COUNT(order_id) AS total_orders
    FROM 
        orders
    GROUP BY
        customer_id,
        EXTRACT(MONTH FROM order_date::date),
        EXTRACT(YEAR FROM order_date::date)
    HAVING
        COUNT(order_id) > 2
)
SELECT
    c.customer_name,
    c.home_address
FROM 
    special_customer sc
    JOIN customers c USING (customer_id)
ORDER BY
    c.customer_name;

-- Task 5
-- Goals: Find the first and last order date of each customer. Show the first 10 data, sorted by customer ID
-- Steps:
-- 1. Select `customer_id`, `MIN(order_date)`, and `MAX(order_date)`:
--    - `MIN(order_date)` identifies the first order date for each customer.
--    - `MAX(order_date)` identifies the last order date for each customer.
-- 2. Group by `customer_id` to calculate the first and last order dates for each customer.
-- 3. Sort the results by `customer_id` in ascending order.
-- 4. Use `LIMIT 10` to retrieve the first 10 rows.

SELECT
    customer_id,
    MIN(order_date) AS first_order,
    MAX(order_date) AS last_order
FROM 
    orders
GROUP BY
    customer_id
ORDER BY
    customer_id
LIMIT 10;

-- Task 6
-- Goals: Retrieve the top 5 customers who have spent the most amount of money on products within the “Trousers” category, 
--			including the customer's name, the quantity and total amount spent in this category. Additionally, find the total 
--			number of products sold in this category and calculate the average total price spent in this category, 
--			compare with the top 5 customers who have spent the most amount of money on products within 
--			the “Trousers” category . Finally, sort the results by the total amount spent in descending order.
-- Steps:
-- 1. Create a CTE `top_5_trouser` to identify the top 5 customers who have spent the most on "Trousers":
--    - Calculate the total amount spent (`SUM(s.quantity * total_price)`) by each customer.
--    - Calculate the total quantity sold (`SUM(s.quantity)`) for each customer.
--    - Group by customer name and limit the results to the top 5 customers, ordered by total amount spent in descending order.
-- 2. Create a CTE `total_avg` to calculate:
--    - The total number of products sold in the "Trousers" category (`SUM(s.quantity)` using a window function).
--    - The average total price spent on products in the "Trousers" category (`AVG(total_price)` using a window function).
--    - Group the calculations by `product_type` to ensure it pertains specifically to "Trousers".
-- 3. Join the `top_5_trouser` CTE with the `total_avg` CTE on `customer_name`.
-- 4. Retrieve the customer name, total amount spent, quantity sold, total products sold, and average total price.
-- 5. Sort the results by the total amount spent in descending order.

WITH top_5_trouser AS (
    SELECT
        c.customer_name,
        SUM(s.quantity * s.total_price) AS total_spent,
        SUM(s.quantity) AS quantity_sold
    FROM
        customers c
        JOIN orders o USING(customer_id)
        JOIN sales s USING(order_id)
        JOIN products p USING(product_id)
    WHERE
        p.product_type = 'Trousers'
    GROUP BY
        c.customer_name
    ORDER BY
        total_spent DESC
    LIMIT 5
), 
total_avg AS (
    SELECT
        SUM(s.quantity) AS total_product_sold,
        AVG(s.total_price) AS avg_total_price
    FROM
        sales s
        JOIN products p USING(product_id)
    WHERE
        p.product_type = 'Trousers'
)
SELECT
    t.customer_name,
    t.total_spent,
    t.quantity_sold,
    ta.total_product_sold,
    ta.avg_total_price
FROM
    top_5_trouser t
    CROSS JOIN total_avg ta
ORDER BY
    t.total_spent DESC;

-- Task 7
-- Goals:  Find the top-selling (Top 1) product for each month. You want to know the product with the highest total quantity 
--			sold in each month. If there are products that have the same total quantity sold, choose the smallest product ID. 
--			Return the product name, the corresponding month, and the total quantity sold for each month's top-selling product. 
--			Sorted by month
-- Steps:
-- 1. Create a CTE `product_quantity_month`:
--    - Extract the month from `order_date` to group products by month.
--    - Calculate the total quantity sold for each product in each month (`SUM(s.quantity)`).
--    - Use `ROW_NUMBER()` to rank products within each month, ordered by total quantity sold in descending order.
--      - If multiple products have the same quantity, prioritize the product with the smallest product ID.
--    - Group by `order_month` and `product_id` to calculate totals.
-- 2. Select the top-selling product for each month by filtering rows with `ROW_NUMBER() = 1` from the CTE.
-- 3. Join with the `products` table to retrieve the product name.
-- 4. Return the product name, order month, and total quantity sold for the top product of each month.
-- 5. Sort the results by month in ascending order.

WITH product_quantity_month AS (
    SELECT
        EXTRACT(MONTH FROM o.order_date::date) AS order_month,
        p.product_id,
        SUM(s.quantity) AS total_quantity_sold,
        ROW_NUMBER() OVER (
            PARTITION BY EXTRACT(MONTH FROM o.order_date::date)
            ORDER BY SUM(s.quantity) DESC, p.product_id
        ) AS row_num
    FROM
        orders o
        JOIN sales s USING(order_id)
        JOIN products p USING(product_id)
    GROUP BY
        order_month, p.product_id
)
SELECT
    p.product_name,
    pqm.order_month,
    pqm.total_quantity_sold
FROM
    product_quantity_month pqm
    JOIN products p USING(product_id)
WHERE
    pqm.row_num = 1
ORDER BY
    pqm.order_month;

-- Task 8
-- Goals: Create a view to store a query for calculating monthly total payment.
-- Steps: 
-- 1. Extract the month from the `order_date` field using the `EXTRACT` function. 
--    This identifies which month the order belongs to.
-- 2. Sum the `payment` column for all orders within each month to calculate the total payment for that month.
-- 3. Group the results by the extracted month (`order_month`) to ensure payments are aggregated correctly.
-- 4. Order the results by `order_month` in ascending order to make the output chronological.

CREATE VIEW monthly_payment AS
	SELECT
	    EXTRACT(MONTH FROM order_date::date) AS order_month, 
	    SUM(payment) AS total_payment
	FROM
		orders
	GROUP BY
	    1                                                    
	ORDER BY
	    1;  

SELECT * FROM monthly_payment
		
-- Task 9
-- Goals: As a warehouse manager responsible for stock management in your company's warehouse, you oversee a warehouse 
--			with a total area of 600,000 sq ft. There are two types of items: prime items and non-prime items. 
--			These items come in various sizes, with priority given to prime items. Your task is to determine 
--			the maximum number of prime and non-prime items that can be stored in the warehouse

-- 			* 	Prime and non-prime items are stored in their respective containers. For example, In the database, 
--				there are 15 non-prime items and 35 prime items. Each prime container must contain 35 prime items, 
--				and each non-prime container must contain 15 non-prime items 
--			*	Non-prime items must always be available in stock to meet customer demand, so the non-prime 
--				item count should never be zero.
-- Steps:
-- 1. Classify items into 'prime' or 'non-prime' based on the `is_prime` field.
-- 2. Calculate the total area occupied by each type (prime and non-prime) using the `SUM` function.
-- 3. Determine the number of containers required for each item type:
--    - Each prime container holds 35 items, and each non-prime container holds 15 items.
-- 4. Calculate the maximum number of containers that can fit in the warehouse (600,000 sq ft):
--    - Divide the total warehouse area by the total size (sq ft) of a container for each item type.
-- 5. Ensure non-prime items are always available by allocating at least one container for non-prime items.
-- 6. Return the maximum number of items (prime and non-prime) that can be stored.

WITH container_size_by_type AS (
    SELECT
        CASE
            WHEN is_prime = 'true' THEN 'prime'
            ELSE 'non-prime'
        END AS item_type,
        SUM(item_size_sqft) AS total_size_sqft
    FROM
        item
    GROUP BY
        1
),
prime_container_count AS (
    SELECT
        total_size_sqft AS prime_total_size_sqft,
        FLOOR(600000 / total_size_sqft) AS prime_max_containers -- Calculate prime containers based on available space
    FROM
        container_size_by_type
    WHERE
        item_type = 'prime'
),
remaining_area AS (
    SELECT
        600000 - (prime_max_containers * prime_total_size_sqft) AS remaining_area
    FROM
        prime_container_count
),
non_prime_container_count AS (
    SELECT
        total_size_sqft AS non_prime_total_size_sqft,
        CASE
            WHEN remaining_area > 0 THEN FLOOR(remaining_area / total_size_sqft)
            ELSE 1 -- Ensure at least one non-prime container
        END AS non_prime_max_containers
    FROM
        container_size_by_type, remaining_area
    WHERE
        item_type = 'non-prime'
),
item_count AS (
    SELECT
        'prime' AS item_type,
        prime_max_containers AS total_containers,
        prime_max_containers * 35 AS total_items -- Prime container holds 35 items
    FROM
        prime_container_count
    UNION ALL
    SELECT
        'non-prime' AS item_type,
        non_prime_max_containers AS total_containers,
        non_prime_max_containers * 15 AS total_items -- Non-prime container holds 15 items
    FROM
        non_prime_container_count
)
SELECT
    item_type,
    total_containers,
    total_items
FROM
    item_count;

-- Task 10
-- Goals: The warehouse manager is planning to find a new warehouse to store their products. The warehouse is expected to 
-- 			accommodate 20 containers for each prime and non-prime item. What is the minimum required size for the warehouse?
-- Steps:
-- 1. Create a CTE `container_size_by_type`:
--    - Classify items into 'prime' or 'non-prime' based on the `is_prime` field.
--    - Calculate the total size occupied by all items of each type using `SUM(item_size_sqft)`.
--    - Group by item type to aggregate sizes for 'prime' and 'non-prime' items separately.
-- 2. Create a CTE `container_requirements`:
--    - Calculate the total area required for 20 containers of each item type.
--    - Multiply the total size per item type by 20 to account for the number of containers.
-- 3. In the main query:
--    - Sum the total area required for all containers (`SUM(total_area_required)`) to find the minimum warehouse size.
-- 4. Return the minimum warehouse size.

WITH container_size_by_type AS (
    SELECT
        CASE
            WHEN is_prime = 'true' THEN 'prime'
            ELSE 'non-prime'
        END AS item_type,
        SUM(item_size_sqft) AS total_size_sqft_per_item
    FROM
        item
    GROUP BY
        1
), 
container_requirements AS (
    SELECT
        item_type,
        total_size_sqft_per_item * 20 AS total_area_required 
    FROM
        container_size_by_type
)
SELECT
    SUM(total_area_required) AS minimum_warehouse_size
FROM
    container_requirements;
