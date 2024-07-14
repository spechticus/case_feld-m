WITH sales_by_order AS (

    SELECT
        s.customer_id,
        s.order_id,
        SUM(s.total_amount_od) AS total_amount_od,
        SUM(s.total_amount_p) AS total_amount_p
    FROM {{ ref('fct_sales') }} s
    GROUP BY 1,2
),
-- we calculate the max amounts in a separate CTE
-- to not compromise the grain when joining to the main query
sales_by_customer AS (
    
    SELECT 
        sbo.customer_id,
        MAX(sbo.total_amount_od) AS max_amount_od,
        MAX(sbo.total_amount_p) AS max_amount_p,
        SUM(sbo.total_amount_od) AS total_amount_by_customer_od,
        SUM(sbo.total_amount_p) AS total_amount_by_customer_p,
        ROW_NUMBER() OVER (ORDER BY SUM(sbo.total_amount_od) DESC) AS sales_rank_od,
        ROW_NUMBER() OVER (ORDER BY SUM(sbo.total_amount_p) DESC) AS sales_rank_p
    FROM sales_by_order AS sbo
    GROUP BY 1

)

SELECT
    c.customer_id,
    c.customer_id_numeric,
    c.company_name_clean,
    c.contact_name_clean,
    c.contact_title,
    c.address_clean,
    c.city_clean,
    c.region,
    c.postal_code,
    c.country,
    c.phone,
    c.fax,
    sbc.max_amount_od,
    sbc.max_amount_p,
    CASE
        WHEN sbc.sales_rank_od <= 10
            THEN TRUE
        ELSE FALSE
    END AS top_10_customer_by_revenue_od,
    CASE
        WHEN sbc.sales_rank_p <= 10
            THEN TRUE
        ELSE FALSE
    END AS top_10_customer_by_revenue_p,
    COUNT(o.order_id) AS number_of_orders

FROM {{ ref('stg_customers') }} c
LEFT JOIN {{ ref('stg_orders') }} o
    USING (customer_id)
LEFT JOIN sales_by_customer AS sbc
    USING (customer_id)
{{ dbt_utils.group_by(n=16) }}