SELECT
    a.product_id,
    a.product_name AS product_name_local,
    {{ replace_local_characters('a.product_name') }} AS product_name_clean,
    a.category_id,
    a.quantity_per_unit,
    a.unit_price,
    a.units_in_stock,
    a.units_on_order,
    a.reorder_level,
    CASE 
        WHEN a.discontinued = 1
            THEN TRUE
        ELSE FALSE 
    END AS discontinued_bool,
    a.units_in_stock < a.units_on_order AS backorders_bool,
    a.units_in_stock < a.reorder_level AS reorder_necessary_bool
    
FROM {{ ref('snapshot_products') }} a
WHERE dbt_valid_to IS NULL