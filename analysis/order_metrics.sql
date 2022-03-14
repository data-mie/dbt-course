with orders as (
    select
        *
    from {{ ref('orders') }}
),

calendar as (
    select
        *
    from {{ ref('calendar') }}
),

daily_metrics as (
    select
        calendar.date_day,
        count(distinct orders.order_id) as orders
    from calendar
    left join orders on (
        calendar.date_day = orders.ordered_at
    )
    group by 1
),

seven_day_rolling_metrics as (
    select
        *,
        sum(orders) over (order by date_day rows between 6 preceding and current row) as orders_last_7_days
    from daily_metrics
)

select
    *
from seven_day_rolling_metrics
order by date_day desc