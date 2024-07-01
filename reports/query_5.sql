-- List of products in the fashion category that were sold lastmonth.

USE
    online_shop_db;
WITH
    fashion_category AS(
    SELECT
        c.id AS fashion_category_id
    FROM
        categories c
    WHERE
        c.category_name = 'Fashion'
)
SELECT
    fashion_products.name AS product_name,
    lastmonthsale.created_at AS date_of_sale
FROM
    order_segments os
JOIN(
    SELECT
        o.id,
        o.created_at
    FROM
        orders o
    WHERE
        o.created_at >= CURRENT_DATE() - INTERVAL 1 MONTH) lastmonthsale
    ON
        os.order_id = lastmonthsale.id
    JOIN(
        SELECT
            *
        FROM
            products p
        JOIN fashion_category f ON
            p.category_id = f.fashion_category_id
    ) fashion_products
ON
    fashion_products.id = os.product_id
