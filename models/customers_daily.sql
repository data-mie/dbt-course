with calendar as (
    select
      *
    from {{ ref('calendar') }}
),

customers_snapshot as (
    select
        *
    from analytics.snapshots_prod.customers_snapshot
),

joined as (
    select
        calendar.date_day,
        customers_snapshot.*
    from calendar
    inner join customers_snapshot on (
        calendar.date_day >= customers_snapshot._dbt_valid_from
        and calendar.date_day < coalesce(customers_snapshot._dbt_valid_to, current_date())
    )
)

select
*
from joined