SELECT
    od.order_id,
    od.product_id,
    o.customer_id,
    o.customer_company_name_cleaned,
    o.order_date,
    MIN(order_date) OVER (PARTITION BY o.customer_id) AS date_of_first_order,
    CASE
        WHEN o.order_date = MIN(order_date) OVER (PARTITION BY o.customer_id)
            THEN 'new customer'
        WHEN o.order_date > MIN(order_date) OVER (PARTITION BY o.customer_id)
            THEN 'returning customer'
        ELSE 'Error! order date before first order date?!'
    END AS new_customer_bool,
    -- N.B. at the required product grain, it would not make a lot of sense to 
    -- list the elapsed time between the first purchase and 'the last purchase'
    -- (as stated in the assignment).
    -- Instead, I rather interpret this assignment as:
    -- "what's the elapsed time between this order and the first one?"
    o.order_date - MIN(order_date) OVER (PARTITION BY o.customer_id) AS elapsed_time_since_first_purchase_for_customer,
    od.unit_price AS unit_price_orderdetails,
    p.unit_price AS unit_price_products,
    od.quantity,
    od.discount,
    -- Because we get 2 different unit prices for the same product in both order_details and products,
    -- we are forking the metric here until we know which one to get rid off (see readme).
    ROUND((od.unit_price * od.quantity)::NUMERIC * (1 - od.discount)::NUMERIC, 2) AS total_amount_od,
    ROUND((p.unit_price * od.quantity)::NUMERIC * (1 - od.discount)::NUMERIC, 2) AS total_amount_p

FROM {{ ref('stg_order_details') }} od
LEFT JOIN {{ ref('stg_orders') }} AS o USING (order_id)
LEFT JOIN {{ ref('stg_products') }} AS P USING (product_id)
{# dbt_utils.group_by(n=8) #}