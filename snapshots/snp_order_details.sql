{% snapshot snapshot_order_details %}

{{
   config(
       unique_key="order_id || '_' || product_id",
   )
}}

SELECT order_id || '_' || product_id AS id, *
FROM {{ source('raw_layer', 'order_details') }}

{% endsnapshot %}