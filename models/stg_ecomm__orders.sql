with sources as (
    {{
        dbt_utils.union_relations(
            relations=[
                source('ecomm', 'orders_us'),
                source('ecomm', 'orders_de'),
                source('ecomm', 'orders_au')
            ],
        )
    }}
),

store_codes as (
    select
        *,
        split_part(split_part(_dbt_source_relation, '.', 3), '_', 2) as store_code
    from sources
),

store_ids as (
    select
        *,
        case
            when store_code = 'us' then 1
            when store_code = 'de' then 2
            when store_code = 'au' then 3
        end as store_id
    from store_codes
),

fields as (
    select
        *,
        id as order_id,
        created_at as ordered_at,
        status as order_status
    from store_ids
)

select
    *
from fields