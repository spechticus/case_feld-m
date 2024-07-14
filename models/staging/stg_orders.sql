SELECT
    a.order_id,
    a.customer_id,
    a.employee_id,
    a.order_date,
    a.required_date,
    a.shipped_date,
    a.ship_via,
    a.freight,
    a.ship_name AS customer_company_name_local,
    {{ replace_local_characters('a.ship_name') }} AS customer_company_name_cleaned,
    a.ship_address AS customer_address_local,
    {{ replace_local_characters('a.ship_address') }} AS customer_address_clean,
    a.ship_city AS customer_city_local,
    {{ replace_local_characters('a.ship_city') }} AS customer_city_clean,
    a.ship_region AS customer_region,
    a.ship_postal_code AS customer_postal_code,
    a.ship_country AS customer_country,
    CASE WHEN a.shipped_date IS NOT NULL
        THEN TRUE 
    ELSE FALSE END AS shipped_bool,
    a.shipped_date::DATE - a.order_date::DATE AS processing_time,
    a.shipped_date > a.required_date AS delayed_bool

FROM {{ ref('snapshot_orders') }} a
WHERE dbt_valid_to IS NULL