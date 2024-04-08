with source as (
    select
        *
    from {{ source('ecomm', 'deliveries') }}
),

fields as (
    select 
        id as delivery_id,
        order_id,
        picked_up_at,
        delivered_at,
        status as delivery_status,
        _synced_at
    from source
)

select 
    *
from fields