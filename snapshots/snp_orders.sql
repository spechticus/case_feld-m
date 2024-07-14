{% snapshot snapshot_orders %}

{{
   config(
       unique_key='order_id',
   )
}}

SELECT *
FROM {{ source('raw_layer', 'orders') }}

{% endsnapshot %}