with orders as (
  select
    *
  from {{ ref('stg_ecomm__orders') }}
),

rates as (
    select
        *
    from {{ ref('conversion_rates') }}
),

order_rates as (
  select
      orders.*,
      rates.rate as rate_usd
  from orders
  left join rates on (
    orders.created_at::date = rates.date_day
    and orders.currency = rates.source_currency
    and rates.target_currency = 'USD'
  )
),

final as (
    select
        *,
        total_amount * rate_usd as total_amount_usd
    from order_rates
)

select
    *
from final