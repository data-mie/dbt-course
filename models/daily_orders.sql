{{
    config(
        materialized='dynamic_table',
        target_lag='1 minute',
        snowflake_warehouse='compute_wh'
    )
}}

-- Note that we're directly referring to the cloned table without using the source macro
-- This is a bad practice and you should avoid it in your own projects
-- In this case, we're doing it to simplify the lab
with orders as (
    select
        *
    from analytics.dbt_stumelius.raw_orders
),

daily_orders as (
    select
        created_at::date as order_date,
        count(*) as order_count,
        sum(total_amount) as total_amount
    from orders
    group by 1
),

final as (
    select
        *
    from daily_orders
)

select
    *
from final