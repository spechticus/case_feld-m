{% snapshot snapshot_customers %}

{{
   config(
       unique_key='customer_id',
   )
}}

SELECT *
FROM {{ source('raw_layer', 'customers') }}

{% endsnapshot %}