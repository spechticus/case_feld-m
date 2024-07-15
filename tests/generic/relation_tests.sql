{% test property_equal_to_reference(
            model, 
            column_name, 
            id_column,
            reference_table, 
            reference_id_column=id_column, 
            property_column_in_reference=column_name) 
            %}
-- When your table references entities from other tables not only by ID (foreign key),
-- but also imports other columns from that entity (properties), 
-- you want to ensure they are matching for integrity.
-- The test is applied on the column of the referencing table.
select
    a.{{id_column}},
    b.{{reference_id_column}} AS reference_id_column,
    a.{{column_name}},
    b.{{property_column_in_reference}}
from
    {{ model }} a
    left join {{ reference_table }} b on a.{{id_column}} = b.{{reference_id_column}}
where
    a.{{column_name}} != b.{{property_column_in_reference}}

{% endtest %}

{% test count_equal_to_array_length(model, count_column, array_column) %}

    select {{ count_column }} , coalesce(array_length({{ array_column }}, 1), 0) 
    from {{ model }}
    where {{ count_column }} != coalesce(array_length({{ array_column }}, 1), 0)

{% endtest %}

{% test rowcount_equal_to_aggregations_from_other_tables(
            model, aggregation_table_1, aggregation_table_2, 
            aggregation_expression_1, aggregation_expression_2,
            operation
        ) %}

        WITH aggregation_1 AS (
        SELECT {{ aggregation_expression_1}} AS value_table1
        FROM {{ aggregation_table_1}} table1	
    ),
    aggregation_2 AS (
        SELECT {{ aggregation_expression_2 }} AS value_table2
        FROM {{ aggregation_table_2 }} table2
    ),
    aggregation_join AS (
        SELECT value_table1, value_table2
        FROM aggregation_1
        CROSS JOIN (SELECT value_table2 FROM aggregation_2) AS aggregation_2
    ),
    aggregation_aggregation AS (
        SELECT value_table1 {{ operation }} value_table2 AS total_aggregate
        FROM aggregation_join
    )
    SELECT a.total_aggregate, model.rowcount
    FROM aggregation_aggregation a
    CROSS JOIN (
        SELECT COUNT(*) AS rowcount
        FROM {{ model }}
    ) model


{% endtest %}