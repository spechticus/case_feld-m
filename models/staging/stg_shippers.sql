SELECT
    a.shipper_id,
    a.company_name AS company_name_local,
    {{ replace_local_characters('a.company_name') }} AS company_name_clean,
    a.phone

FROM {{ ref('snapshot_shippers') }} a
WHERE dbt_valid_to IS NULL