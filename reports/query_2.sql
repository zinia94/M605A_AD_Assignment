-- 10 best-selling products with the total amount and their supplier.

USE online_shop_db;

WITH product_sales AS (
    SELECT
        os.product_id,
        SUM(os.quantity) AS total_quantity
    FROM
        order_segments os
    JOIN orders o ON os.order_id = o.id
    GROUP BY os.product_id
)
SELECT
    p.name AS product_name,
    s.company_name as supplier_company,
    ps.total_quantity AS total_number_of_sell,
    COALESCE(s.website, 'No Website') AS suppliers_website
FROM
    product_sales ps
JOIN product_suppliers psup ON ps.product_id = psup.product_id
JOIN products p ON p.id = ps.product_id
JOIN suppliers s ON s.id = psup.supplier_id
ORDER BY
    ps.total_quantity DESC
LIMIT 10;