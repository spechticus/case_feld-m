{% snapshot snapshot_employees %}

{{
   config(
       unique_key='employee_id',
   )
}}

SELECT *
FROM {{ source('raw_layer', 'employees') }}

{% endsnapshot %}