{% snapshot snapshot_products %}

{{
   config(
       unique_key='product_id',
   )
}}

SELECT *
FROM {{ source('raw_layer', 'products') }}

{% endsnapshot %}