-- List of customers and their total purchases.
USE
    online_shop_db;
SELECT
    CONCAT(c.first_name, ' ', c.last_name) AS customers_name,
    CONCAT(
        c.address,
        ', ',
        c.state,
        ' - ',
        c.post_code,
        ' ',
        c.country
    ) AS address,
    p.number_of_orders AS total_purchases
FROM
    customers c
JOIN(
    SELECT
        o.customer_id,
        COUNT(id) AS number_of_orders
    FROM
        orders o
    GROUP BY
        o.customer_id
) p
ON
    c.id = p.customer_id