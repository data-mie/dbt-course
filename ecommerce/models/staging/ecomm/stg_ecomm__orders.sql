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

renamed as (
    select
        *,
        id as order_id,
        created_at as ordered_at,
        status as order_status
    from store_ids
),

add_us_store_currency as (
    select
        * exclude (currency),
        case
            when store_code = 'us' then 'USD'    
            else currency
        end as currency
    from renamed
),

deduplicated as (
    {{
        dbt_utils.deduplicate(
            relation='add_us_store_currency',
            partition_by='order_id',
            order_by='_synced_at desc',
        )
    }}
)

select
    *
from deduplicated