{% snapshot customers_snapshot %}

{{
    config(
      target_database='analytics',
      target_schema='snapshots_stumelius',
      unique_key='id',
      strategy='check',
      check_cols = 'all',
    )
}}

select
    *
from {{ source('ecomm', 'customers') }}

{% endsnapshot %}