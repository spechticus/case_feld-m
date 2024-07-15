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


-- Create a date spine for all months between the dates calculated above
-- then cross-join with all available countries to form the background
-- on which we will project the data through left joins
WITH date_spine AS (
    {{ dbt_utils.date_spine(
        datepart="month",
        start_date="cast(" ~ mindate ~ "as date)",
        end_date="cast(" ~ maxdate ~ "as date)"
    ) }}
),
date_country_spine AS (
    SELECT
        d.date_month,
        c.country
    FROM date_spine d
    CROSS JOIN (SELECT DISTINCT country FROM {{ ref('dim_customer') }}) c
),
-- get membership information about the cohorts:
-- which customer_ids are in it and how many?
cohorts AS (
    SELECT
        DATE_TRUNC('month', c.date_of_first_order) AS month_of_first_order,
        c.country,
        COUNT(c.customer_id_numeric) AS customer_count,
        ARRAY_AGG(c.customer_id_numeric) AS customer_id_array
    FROM {{ ref('dim_customer') }} AS c
    GROUP BY 1,2
),
-- Then figure out how much total revenue each customer made
-- to later sum these numbers per cohort
total_revenue_per_customer AS (
    SELECT
        c.customer_id_numeric,
        SUM(s.total_amount_od) AS total_customer_amount_od,
        SUM(s.total_amount_p) AS total_customer_amount_p

    FROM {{ ref('fct_sales') }} AS s
        LEFT JOIN {{ ref('dim_customer') }} c
        USING (customer_id)
    GROUP BY 1
),
total_sales_by_cohort AS (
    SELECT
        co.month_of_first_order AS cohort_month,
        co.country AS cohort_country,
        SUM(trc.total_customer_amount_od) AS total_cohort_amount_od,
        SUM(trc.total_customer_amount_p) AS total_cohort_amount_p
    FROM total_revenue_per_customer AS trc
    JOIN cohorts co ON trc.customer_id_numeric = ANY(co.customer_id_array)
    GROUP BY 1,2
)
-- Then put it all together:
-- Take the spine and join the data,
-- COALESCE-ing where there are none
    SELECT
        dcs.date_month,
        dcs.country,
        COALESCE(co.customer_count, 0) AS customer_count,
        COALESCE(co.customer_id_array, ARRAY[]::INTEGER[]) AS customer_ids,
        COALESCE(tsc.total_cohort_amount_od, 0) AS total_cohort_amount_od,
        COALESCE(tsc.total_cohort_amount_p, 0) AS total_cohort_amount_p

    FROM date_country_spine AS dcs
    -- Left join cohorts and sales so we can see which months are "empty"
    LEFT JOIN cohorts AS co
        ON dcs.date_month = co.month_of_first_order
        AND dcs.country = co.country
    LEFT JOIN total_sales_by_cohort AS tsc
        ON dcs.date_month = tsc.cohort_month
        AND co.country = tsc.cohort_country
    ORDER BY dcs.date_month, dcs.country