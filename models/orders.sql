{{
    config(
        materialized='incremental',
        unique_key='order_id'
    )
}}

with orders as (
    select
        *
    from {{ ref('stg_ecomm__orders') }}
    {% if is_incremental() %}
        where ordered_at > (select dateadd('day', -3, max(ordered_at)) from {{ this }})
    {% endif %}
),

deliveries as (
    select
        *
    from {{ ref('stg_ecomm__deliveries') }}
),

deliveries_filtered as (
    select
        *
    from deliveries
    where delivery_status = 'delivered'
),

customers as (
    select
        *
    from {{ ref('stg_ecomm__customers') }}
),

stores as (
    select
        *
    from {{ ref('stores') }}
),

joined as (
    select
        orders.order_id,
        orders.customer_id,
        orders.ordered_at,
        orders.order_status,
        orders.total_amount,
        orders.store_id,
        stores.store_name,
        datediff('minutes', orders.ordered_at, deliveries_filtered.delivered_at) as delivery_time_from_order,
        datediff('minutes', deliveries_filtered.picked_up_at, deliveries_filtered.delivered_at) as delivery_time_from_collection
    from orders
    left join stores on (orders.store_id = stores.store_id)
    left join deliveries_filtered on (orders.order_id = deliveries_filtered.order_id)
    left join customers on (orders.customer_id = customers.customer_id)
    where customers.email not ilike '%ecommerce.com'
        and customers.email not ilike '%ecommerce.ca'
        and customers.email not ilike '%ecommerce.co.uk'
),

days_since_last_order as (
    select
        *,
        datediff(
            'day', 
            lag(ordered_at) over (partition by customer_id order by ordered_at),
            ordered_at
        ) as days_since_last_order
    from joined
)

select
    *
from days_since_last_order