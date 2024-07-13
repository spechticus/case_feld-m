{% test character_parsed_correctly(model, column_name)%}
    -- When a special character would be wrongly parsed it would result
    -- in the character "�"
    select
        {{ column_name }}
    from
        {{ model }}
    where
        {{ column_name }} like '%�%'

{% endtest %}