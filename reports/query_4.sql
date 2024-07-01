-- List of returned items.
USE
    online_shop_db;
SELECT
    p.name AS product_name,
    cro.number_of_item_returned,
    COALESCE(
        p.description,
        'No Description Available'
    ) AS description
FROM
    products p
JOIN(
    SELECT
        ro.product_id,
        SUM(ro.quantity) AS number_of_item_returned
    FROM
        returned_orders ro
    GROUP BY
        ro.product_id
) cro
ON
    p.id = cro.product_id