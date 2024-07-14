SELECT
   a.employee_id,
   a.first_name AS first_name_local,
   {{ replace_local_characters('a.first_name')}} AS first_name_clean,
   a.last_name AS last_name_local,
   {{ replace_local_characters('a.last_name')}} AS last_name_clean,
   a.birth_date,
   a.hire_date,
   a.address AS address_local,
   {{ replace_local_characters('a.address') }} AS address_clean,
   a.city AS city_local,
   {{ replace_local_characters('a.city') }} AS city_clean,
   a.region,
   a.postal_code,
   a.country,
   a.home_phone,
   a.extension,
   a.photo::BYTEA,
   a.photo_path

FROM {{ ref('snapshot_employees') }} a
WHERE dbt_valid_to IS NULL