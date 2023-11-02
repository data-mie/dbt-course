{{ config(materialized='ephemeral') }}

with orders as (
    select
        *
    from {{ ref('orders') }}
),

seven_weeks as (
    select distinct
        customer_id
    from orders
    where ordered_at > current_date - 42
)

select
    *
from seven_weeks