{% snapshot orders_snapshot %}

{{
    config(
    target_database='analytics',
    target_schema='snapshots_stumelius',
    unique_key='id',

    strategy='timestamp',
    updated_at='_synced_at',
    )
}}

select
    *
from {{ source('ecomm', 'orders') }}

{% endsnapshot %}