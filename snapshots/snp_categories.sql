{% snapshot snapshot_categories %}

{{
   config(
       unique_key='category_id',
   )
}}

SELECT *
FROM {{ source('raw_layer', 'categories') }}

{% endsnapshot %}