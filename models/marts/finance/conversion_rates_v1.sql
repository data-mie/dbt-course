with rates_usd as (
    select
        *
    from {{ ref('stg_finance__conversion_rates_usd') }}
),

fields as (
    select
        conversion_rate_id,
        date_day,
        currency,
        rate_usd as rate_usd
    from rates_usd
),

final as (
    select
        *
    from fields
)

select
    *
from final