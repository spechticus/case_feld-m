-- tells the compiler to run fct_sales before this model
-- depends_on: {{ ref('fct_sales') }}
-- tells the compiler to run the following Jinja at runtime
{% if execute %}
    {# Dynamically pull the MIN and MAX order date #}
    {% set mindate_query = "SELECT MIN(DATE_TRUNC('month', order_date))::DATE::TEXT FROM models_data_marts.fct_sales" %}
    {% set mindate_result = run_query(mindate_query) %}
    {% set maxdate_query = "SELECT MAX(DATE_TRUNC('month', order_date))::DATE::TEXT FROM models_data_marts.fct_sales" %}
    {% set maxdate_result = run_query(maxdate_query) %}
    {% set mindate_value = mindate_result.columns[0].values()[0] %}
    {% set maxdate_value = maxdate_result.columns[0].values()[0] %}
    {% set mindate = "'" ~ mindate_value ~ "'" %}
    {% set maxdate = "'" ~ maxdate_value ~ "'" %}

{% endif %}


-- Create a date spine in months between the dates calculated above
WITH date_spine AS (
    {{ dbt_utils.date_spine(
        datepart="month",
        start_date="cast(" ~ mindate ~ "as date)",
        end_date="cast(" ~ maxdate ~ "as date)"
    ) }}
),
cohorts AS (
    SELECT
        DATE_TRUNC('month', c.date_of_first_order) AS month_of_first_order,
        c.country,
        COUNT(c.customer_id_numeric) AS customer_count
    FROM {{ ref('dim_customer') }} AS c
    GROUP BY 1,2
),
monthly_sales_by_country AS (
    SELECT
        s.customer_country,
        DATE_TRUNC('month', s.order_date::DATE) AS sales_month,
        SUM(s.total_amount_od) AS monthly_amount_od,
        SUM(s.total_amount_p) AS monthly_amount_p
    FROM {{ ref('fct_sales') }} AS s
    GROUP BY 1,2
)
    SELECT
        date_month,
        co.country,
        co.customer_count,
        msc.monthly_amount_od,
        msc.monthly_amount_p

    FROM date_spine
    -- Left join the cohorts so we can see which months are "empty"
    LEFT JOIN cohorts AS co
        ON date_spine.date_month = co.month_of_first_order
    LEFT JOIN monthly_sales_by_country AS msc
        ON date_spine.date_month = msc.sales_month
            AND co.country = msc.customer_country