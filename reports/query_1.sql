-- Detail information about suppliers and the number of products that they provide.
USE
    online_shop_db;
SELECT
    s.company_name,
    a.total_products AS total_products_supplied,
    s.website,
    CONCAT(
        s.address,
        ', ',
        s.state,
        ' - ',
        s.post_code,
        ' ',
        s.country
    ) AS address,
    CONCAT(
        'Name: ',
        s.contact_name,
        ', Title: ',
        s.contact_title,
        ', Email: ',
        s.email,
        ', Phone No: ',
        s.phone_no
    ) AS contact_details,
    s.description,
    (
        CASE s.is_active WHEN 1 THEN 'TRUE' ELSE 'FALSE'
    END
) AS is_active
FROM
    suppliers s
INNER JOIN(
    SELECT
        ps.supplier_id,
        SUM(ps.quantity) AS total_products
    FROM
        product_suppliers ps
    GROUP BY
        ps.supplier_id
) a
ON
    s.id = a.supplier_id;