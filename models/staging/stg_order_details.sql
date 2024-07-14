SELECT
    a.order_id,
    a.product_id,
    a.unit_price,
    a.quantity,
    a.discount

FROM {{ ref('snapshot_order_details') }} a
WHERE dbt_valid_to IS NULL