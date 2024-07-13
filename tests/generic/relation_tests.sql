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