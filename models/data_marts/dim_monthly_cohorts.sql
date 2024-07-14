-- depends_on: {{ ref('fct_sales') }}
{% if execute %}
  
    {% set mindate_query = "SELECT MIN(DATE_TRUNC('month', order_date))::DATE::TEXT FROM models_data_marts.fct_sales" %}
    {% set mindate_result = run_query(mindate_query) %}
    {% set maxdate_query = "SELECT MAX(DATE_TRUNC('month', order_date))::DATE::TEXT FROM models_data_marts.fct_sales" %}
    {% set maxdate_result = run_query(maxdate_query) %}
    {% set mindate_value = mindate_result.columns[0].values()[0] %}
    {% set maxdate_value = maxdate_result.columns[0].values()[0] %}
    {% set mindate = "'" ~ mindate_value ~ "'" %}
    {% set maxdate = "'" ~ maxdate_value ~ "'" %}

{% endif %}



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
        COUNT(customer_id_numeric) AS customer_count
    FROM {{ ref('dim_customer') }} AS c
    GROUP BY 1,2
)
    SELECT
        date_month,
        co.country,
        co.customer_count

    FROM date_spine
    LEFT JOIN cohorts AS co
        ON date_spine.date_month = co.month_of_first_order