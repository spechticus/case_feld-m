SELECT

   a.category_id,
   a.category_name,
   a.description,
   --parsing the Hex to Binary
   a.picture::BYTEA

FROM {{ ref('snapshot_categories') }} a
WHERE dbt_valid_to IS NULL