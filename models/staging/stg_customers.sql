SELECT

   a.customer_id,
   -- the customer_id seems to be following no particular logic
   -- and might be human-created. To avoid errors and to enforce
   -- an automatically created numeric ID, we simply assign the row number
   -- to each available client
   ROW_NUMBER() OVER () AS customer_id_numeric,
   a.company_name AS company_name_local,
   -- the company names and contact names contain local characters
   -- these can cause inconsistencies and problems so it might be worth
   -- appending cleaned/stripped versions of these columns
   {{ replace_local_characters('a.company_name') }} AS company_name_clean,
   a.contact_name AS contact_name_local,
   {{ replace_local_characters('a.contact_name') }} AS contact_name_clean,
   



FROM {{ ref('snapshot_customers') }} a
WHERE dbt_valid_to IS NULL