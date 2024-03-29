## Lab 7: Data Modeling, Project Structure and dbt Packages

❗Remember to create a development branch `lab-7` at the beginning of the lab and at the end commit your changes to it and then merge the branch back to `main`.

### 1. Review the `dbt_utils` package 

[dbt_utils](https://hub.getdbt.com/dbt-labs/dbt_utils/latest/) contains many useful tests and macros that can be reused across dbt projects. The first task is to:

(1.1) Check the generic tests and macros in `dbt_utils` and discuss the ones you find useful or interesting with your peers
    
* e.g., `expression_is_true`, `at_least_one`, `get_column_values`, `deduplicate`, `star`, `union_relations`

(1.2) Make sure you have `dbt_utils` version `>=1.1.0` listed in your project dependencies in the `packages.yml` file

(1.3) Run `dbt deps` to ensure the required version of `dbt_utils` is installed

### 2. Organize models into folders

Organize your models into the following project structure:

    models
    ├── staging
    │   ├── ecomm
    │   │   ├── stg_ecomm__customers.sql
    │   │   ├── stg_ecomm__deliveries.sql
    │   │   ├── stg_ecomm__orders.sql
    │   │   └── ...
    │   └── stripe
    │       ├── stg_stripe__payments.sql
    │       └── ...
    ├── marts
    │   └── ecomm
    │       ├── orders.sql
    │       ├── customers.sql
    │       └── ...
    ├── calendar.sql
    ├── schema.yml
    ├── sources.yml
    └── ...

Also think about the following:

* How would you reorganize sources in the `sources.yml` to better fit the new project structure?
* How about models in the `schema.yml`? How would you reorganize them?

### 3. Add new ecommerce stores

Your company is opening new ecommerce stores in Germany and Australia! Your data engineering team has modified the ecommerce orders pipeline so that it now feeds the orders data into store specific tables: 

* `raw.ecomm.orders_us` (`store_id`: 1),
* `raw.ecomm.orders_de` (`store_id`: 2), and
* `raw.ecomm.orders_au` (`store_id`: 3).

Rewrite `stg_ecomm__orders` so that it creates an union of the three orders tables and adds a `store_id` column based on the table from which the order comes from. 

<details>
  <summary>👉 Section 3</summary>

  (3.1) Add the three orders tables to your `sources.yml`: `orders_us`, `orders_de` and `orders_au`

  (3.2) Refactor `stg_ecomm__orders` so that it combines the three orders tables using the `dbt_utils.union_relations` macro:

  ```sql
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

    ...
  ```

  (3.3) Preview and inspect the compiled SQL of `stg_ecomm__orders`. How does the `dbt_utils.union_relations` macro differ from a manually constructed union?

  (3.4) Extract store country code from the `_dbt_source_relation` column and map it to the `store_id` in the `stg_ecomm__orders` model
  ```sql
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
    )

    select
        *
    from renamed
  ```
  (3.5) Ensure the model and its downstream depencies run successfully `dbt run -s stg_ecomm__orders+`

  (3.6) Add a `not_null` test for the `store_id` column in `stg_ecomm__orders` and run the tests: `dbt test -s stg_ecomm__orders+`. Note that the `stg_ecomm__orders` unique test is failing and we'll come to that in the next section of the lab.

</details>

### 4. Deduplicate orders

You receive an email from the data eng team notifying you that they've introduced a bug to the data pipeline which is creating duplicate orders in the new tables. The data must get to production ASAP so there's no time to wait for the data eng team to implement and deploy the fix. Your team decides to deal with the duplicates in dbt and you're tasked with implementing the deduplication logic in `stg_ecomm__orders` so that the deduplication automatically propagates to downstream models.

<details>
  <summary>👉 Section 4</summary>

(4.1) Find the duplicates using SQL:

```sql
select
    *
from analytics.dbt_<first_initial><last_name>.stg_ecomm__orders
where order_id in (
    select
        order_id
    from analytics.dbt_<first_initial><last_name>.stg_ecomm__orders
    group by 1
    having count(*) > 1
)
order by order_id
```

(4.2) Use the `dbt_utils.deduplicate` macro to deduplicate orders in `stg_ecomm__orders`. Which columns should you partition and group by?
```sql
...
renamed as (
    select
        *,
        id as order_id,
        created_at as ordered_at,
        status as order_status
    from store_ids
),

deduplicated as (
    {{
        dbt_utils.deduplicate(
            relation='renamed',
            partition_by='<partition-by-column>',    -- TODO: Add partition_by column
            order_by='<order-by-column> desc'        -- TODO: Add order_by column
        )
    }}
)

select
    *
from deduplicated
```

(4.3) Ensure the model and its downstream depencies run successfully: `dbt run -s stg_ecomm__orders+`

(4.4) Add a primary key test for `order_id` in `stg_ecomm__orders` and run the tests: `dbt test -s stg_ecomm__orders+`

</details>

### 5. Add currency conversions

Order amounts in the DE and AU tables are in EUR and AUD currencies, respectively, and they need to be converted to USD. The finance team has provided you with a currency conversion table: `raw.finance.conversion_rates_usd`. You're tasked with the implementation of an intermediate `int_ecomm__orders_enriched` model that converts the orders amounts to USD.


<details>
  <summary>👉 Section 5</summary>

(5.1) Add the `finance` source with the `conversion_rates_usd` table to `sources.yml`:

```
# models/sources.yml
version: 2

sources:
  - name: finance
    database: raw
    tables:
      - name: conversion_rates_usd

...
```

(5.2) Create a `stg_finance__conversion_rates_usd` model in a `models/staging/finance` folder. Include a `conversion_rate_id` primary key using `dbt_utils.generate_surrogate_key`. Also, add tests for the primary key in the `schema.yml`

```sql
with source as (
    select
        *
    from {{ source('finance', 'conversion_rates_usd') }}
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(["date_day", "currency"]) }} as conversion_rate_id,
        *
    from source
)

select
    *
from final
```

(5.3) Create a `int_ecomm__orders_enriched` model in the `models/staging/ecomm` folder that adds a `total_amount_usd` to `stg_ecomm__orders`

```sql
with orders as (
  select
    *
  from {{ ref('stg_ecomm__orders') }}
),

rates as (
    select
        *
    from {{ ref('stg_finance__conversion_rates_usd') }}
),

order_rates as (
  select
      orders.*,
      ... as rate_usd        -- TODO: Fill the logic
  from orders
  left join rates on (
    ...                      -- TODO: Fill the join
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
```

(5.4) Add primary key and `total_amount_usd` `not_null` tests in the `schema.yml`

(5.4) Ensure the model and its upstream depencies run successfully: `dbt run -s +int_ecomm__orders_enriched`

(5.5) Run the tests: `dbt test -s +int_ecomm__orders_enriched`. Does the `total_amount_usd` `not_null` test fail? Why?

</details>
