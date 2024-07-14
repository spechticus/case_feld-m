{% snapshot snapshot_shippers %}

{{
   config(
       unique_key='shipper_id',
   )
}}

SELECT *
FROM {{ source('raw_layer', 'shippers') }}

{% endsnapshot %}