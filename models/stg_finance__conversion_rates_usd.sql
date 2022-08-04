with source as (
    select
        *
    from {{ source('finance', 'conversion_rates_usd') }}
),

final as (
    select
        {{ dbt_utils.surrogate_key(["date_day", "currency"]) }} as conversion_rate_id,
        *
    from source
)

select
    *
from final