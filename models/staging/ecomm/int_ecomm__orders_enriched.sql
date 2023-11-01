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
      case
        when orders.store_code = 'us' then 1
        else rates.rate_usd
      end as rate_usd
  from orders
  left join rates on (
    orders.created_at::date = rates.date_day
    and orders.currency = rates.currency
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