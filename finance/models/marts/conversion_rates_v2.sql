with rates_usd as (
    select
        *
    from {{ ref('stg_finance__conversion_rates_usd') }}
),

fill_usd as (
    select
        date_day,
        currency,
        rate_usd
    from rates_usd

    union all

    select distinct
        date_day,
        'USD' as currency,
        1 as rate_usd
    from rates_usd
),

fields as (
    select
        date_day,
        currency as source_currency,
        'USD' as target_currency,
        rate_usd as rate
    from fill_usd
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(["date_day", "source_currency", "target_currency"]) }} as conversion_rate_id,
        *
    from fields
)

select
    *
from final