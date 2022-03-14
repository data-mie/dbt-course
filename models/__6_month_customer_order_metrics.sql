{{ config(materialized='ephemeral') }}

with orders as (
    select
        *
    from {{ ref('orders') }}
), 

metrics as (    
    select
        customer_id,
        round(avg(total_amount), 2) as avg_order_amount,
        count(*) as order_count
    from orders
    where ordered_at > current_date - 180
    group by 1
)

select
    *
from metrics