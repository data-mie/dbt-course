## Lab 7: Data Modeling, Project Structure and dbt Packages

### 1. The `dbt_utils` package 

[dbt_utils](https://hub.getdbt.com/dbt-labs/dbt_utils/latest/) contains many useful tests and macros that can be reused across dbt projects. 

1. Check the generic tests and macros in `dbt_utils` and discuss the ones you find useful or interesting with your peers
    * e.g., `expression_is_true`, `at_least_one`, `get_column_values`, `deduplicate`, `star`, `union_relations`

2. Make sure you have `dbt_utils` version `>=0.8.5` listed in your project dependencies in the `packages.yml` file

3. Run `dbt deps` to ensure the required version of `dbt_utils` is installed

### 2. New ecommerce stores

Your company is opening new ecommerce stores in Germany and Australia! Your data engineering team modifies the ecommerce data pipeline so that it nopw feeds the orders data into store specific tables: 

* `raw.ecomm.orders_us` (`store_id`: 1),
* `raw.ecomm.orders_de` (`store_id`: 2), and
* `raw.ecomm.orders_au` (`store_id`: 3).

Rewrite the `stg_ecomm__orders` model so that it creates an union of the three orders tables and adds a `store_id` column based on the table from which the order comes from. 

<details>
  <summary>👉 Section 2</summary>

  (1) Add the three orders tables to your `sources.yml`
  (2) Refactor the `stg_ecomm__orders` model so that it combines the three orders tables using the `dbt_utils.union_relations` macro:

  ```sql
    with sources as (
        {{
            dbt_utils.union_relations(
                relations=[
                    ...
                ],
            )
        }}
    ),

    ...
  ```
  (3) Preview and inspect the compiled SQL of `stg_ecomm__orders`. How does the `dbt_utils.union_relations` macro differ from a manually constructed union?
  (4) Extract store country code from the `_dbt_source_relation` column and map it to the `store_id`
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
            ... as store_code
        from sources
    ),

    store_ids as (
        select
            *,
            ... as store_id
        from store_codes
    ),

    renamed as (
        select
            *,                  -- Include all original columns in the staging layer
            id as order_id,
            ...
        from store_ids
    )

    select
        *
    from renamed
  ```
  (5) Run the model and its downstream dependencies: `dbt run -s stg_ecomm__orders+`
  (6) Add a `not_null` test for the `store_id` column in `stg_ecomm__orders` and run the tests: `dbt test -s stg_ecomm__orders+`

</details>

### 3. Orders deduplication

After reviewing the orders data you notice that there are duplicate orders in the tables. The data engineering team must have introduced a bug to the data pipeline 🤦 The data must get to production ASAP so there's no time to wait for the data eng team to implement and deploy the fix. Your team has decided to deal with the duplicates in dbt and you're tasked with the implementation.

(1) Find the duplicates

(2) Use the `dbt_utils.deduplicate` macro to deduplicate orders in `stg_ecomm__orders`
```sql
...

renamed as (
    ...
),

deduplicated as (
    {{
        dbt_utils.deduplicate(
            ...
        )
    }}
)

select
    *
from deduplicated
```

(3) Ensure the model and its downstream depencies still run: `dbt run -s stg_ecomm__orders+`

(4) Add a primary key test for `order_id` in `stg_ecomm__orders` and run the tests: `dbt test -s stg_ecomm__orders+`

<details>
  <summary>👉 Section 3</summary>

  (1) Todo

</details>

### 4. Calculate metrics in a mart model

