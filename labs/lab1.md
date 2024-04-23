## Lab 1: Models, Sources and Docs

### 0. Create a development branch for the lab

Before going into this lab you need to create a development branch where you can make changes to the project. The `main` branch is read-only and therefore cannot be directly written to. To create a new branch click the 'Create branch' in the top left corner, name the branch `lab-1` and click 'Submit'.

### 1. Re-factor your current model by creating two new staging models

So far, we've created one `customers` model in the [pre-course work](../pre-course/pre_course.md). That model references two raw tables from our warehouse and 'cleans' up some of that data. Create two new models, `stg_ecomm__orders` and `stg_ecomm__customers`, that do that clean-up. Then, re-factor the existing `customers` model to reference those staging models.

<details>
  <summary>👉 Section 1</summary>

  (1) Create a new file in the `models/` directory called `stg_ecomm__orders.sql` that contains the following SQL:

  ```sql
  with source as (
    select
      *
    from raw.ecomm.orders
  ),

  renamed as (
    select
      id as order_id,
      *,
      created_at as ordered_at,
      status as order_status
    from source
  ),

  final as (
    select
      *
    from renamed
  )

  select
    *
  from final
  ```
  (2) Create a new file in the `models/` directory called `stg_ecomm__customers.sql` that contains the following SQL:

  ```sql
  with source as (
    select
      *
    from raw.ecomm.customers
  ),

  renamed as (
    select
      id as customer_id,
      *
    from source
  ),

  final as (
    select
      *
    from renamed
  )

  select
    *
  from final
  ```
  (3) Re-factor the top two CTEs of our original `customers` model to select from our new models using the `ref` macro. The first CTE should now be:

  ```sql
  select
    *
  from {{ ref('stg_ecomm__orders') }}
  ```

  (4) Execute `dbt run` in the console at the bottom of your screen to make sure everything is working. (This will be the final step of many sections. Eventually I'll stop listing it explicitly.)
</details>

### 2. Add sources to the project

Refactor your project from your pre-work by adding in sources wherever you had hard-coded references to the `ecomm` tables.

Things to think about:
* Do you want the source name to be the same as the schema name?
* Should you be applying a source freshness check to the data?

<details>
  <summary>👉 Section 2</summary>

  (1) Create a new file in the `models/` directly called `sources.yml`. At a minimum, the file should have the following information:
  ```yml
  version: 2

  sources:
    - name: ecomm
      database: raw
      tables:
        - name: customers
        - name: orders
  ```

  (2) Replace the hard-coded table references in `stg_ecomm__orders` and `stg_ecomm__customers` with the source function. The source function looks like:
  ```sql
  {{ source('ecomm', 'customers') }}
  ```

  (3) Execute `dbt run` in the console to make sure everything is working.

</details>

### 3. Add documentation to your models and sources

Now that we've removed all hard-coded references to our source data, we should document our models and sources.

Things to think about:
* Do I have any repeated definitions that I should use `doc` blocks for?
* What information is important in a column definition?

<details>
  <summary>👉 Section 3</summary>

  (1) Update your `sources.yml` file with descriptions for either the tables or the columns. In this example, I have added a description to each table:
  ```yml
  version: 2

  sources:
    - name: ecomm
      database: raw
      tables:
        - name: customers
          description: Each record in this table represents a customer in our ecommerce application.
        - name: orders
          description: Each record in this table represents an order in our ecommerce application.
  ```

  (2) Create a new file in the `models/` directory called `schema.yml`. In this example, I have added table descriptions and some column descriptions:
  ```yml
  version: 2

  models:
    - name: customers
      description: Each record represents a customer.
      columns:
        - name: customer_id
          description: A unique customer ID from our ecommerce application.
        - name: first_name
          description: A customer's first name.
        - name: last_name
          description: A customer's last name.
        - name: count_orders
          description: The number of orders a customer has had all-time.
        - name: first_order_at
          description: The timestamp of a customer's first order.
        - name: most_recent_order_at
          description: The timestamp of a customer's most recent order.
  ```

  (3) Execute `dbt docs generate` in the console to make sure everything is working. If it runs successfully, you can click in the top left corner to see your auto-generated documentation.

</details>

### 4. Add a new source table to the project

A new table has arrived in our warehouse, `raw.ecomm.deliveries`. The `deliveries` table looks like this:

| id | order_id | picked_up_at     | delivered_at     | status    | _synced_at       |
|----|----------|------------------|------------------|-----------|------------------|
| 1  | 1        | 2020-01-01 08:45 | 2020-01-01 09:12 | delivered | 2020-06-01 12:13 |
| 2  | 2        | 2020-01-01 08:57 | 2020-01-01 09:10 | delivered | 2020-06-01 12:13 |
| 3  | 3        | 2020-01-01 09:01 |                  | cancelled | 2020-06-01 12:13 |

We want to add this table as a source to our project. 

<details>
  <summary>👉 Section 4</summary>

  (1) Add the `deliveries` table in your `models/sources.yml` file.

</details>

### 5. Create an `orders` model that includes delivery time dimensions

Now that we have our new `deliveries` data, our partnerships team wants to know how long deliveries took for each order.

Create an `orders` model that calculates `delivery_time_from_collection` and `delivery_time_from_order`. The columns should contain the amount of time in minutes that it took to for the order to be delivered from collection and ordering respectively.

<details>
  <summary>👉 Section 5</summary>

  (1) While we could reference the source table directly in the orders model, we'll follow the standard we've set above and create an `stg_` model for the deliveries table. Create a new file in the `models/` directory called `stg_ecomm__deliveries.sql` that contains the following SQL:
  ```sql
  with source as (
    select
        *
    from {{ source('ecomm', 'deliveries') }}
  ),

  renamed as (
    select
      id as delivery_id,
      *,
      status as delivery_status
    from source
  ),

  final as (
    select
      *
    from renamed
  )

  select
    *
  from final
  ```

  (2) Create a new file in the `models/` directory called `orders.sql` that contains the following SQL:
  ```sql
  with orders as (
    select 
      *
    from {{ ref('stg_ecomm__orders') }}
  ),
  
  deliveries as (
    select
      *
    from {{ ref('stg_ecomm__deliveries') }}
  ),
  
  deliveries_filtered as (
    select 
      *
    from deliveries
    where delivery_status = 'delivered'
  ),
  
  joined as (
    select
      orders.order_id,
      orders.customer_id,
      orders.ordered_at,
      orders.order_status,
      orders.total_amount,
      orders.store_id,
      datediff('minutes', orders.ordered_at, deliveries_filtered.delivered_at) as delivery_time_from_order,
      datediff('minutes', deliveries_filtered.picked_up_at, deliveries_filtered.delivered_at) as delivery_time_from_collection
    from orders
    left join deliveries_filtered on (orders.order_id = deliveries_filtered.order_id)
  )

  select
    *
  from joined
  ```

  (3) Execute `dbt run -s orders` in the console. What happens, do you get an error? If so, why and how can you fix it? Rerun the model with the `-d` / `--debug` flag to debug the process and see what's going on.

</details>

### 6. Add average delivery times to the customers model

We've got two new columns in our `orders` model. Our retention team wants to understand how the average delivery times affect customer churn.

Add `average_delivery_time_from_collection` and `average_delivery_time_from_order` columns to your `customers` model. These fields will be used by the retention team to correlate delivery times and customer retention.

<details>
  <summary>👉 Section 6</summary>

  (1) In the `orders` CTE in the `customers` model, replace `{{ ref('stg_ecomm__orders') }}` with `{{ ref('orders') }}`. The model will now reference our new orders model instead of the original `stg_` model.

  (2) In our `customer_metrics` CTE, add two new lines for the average delivery time metrics:
  ```sql
  avg(delivery_time_from_collection) as average_delivery_time_from_collection,
  avg(delivery_time_from_order) as average_delivery_time_from_order,
  ```

  (3) Finally, add those two new fiels in your `joined` CTE.

  (4) Execute `dbt run` in the console to make sure everything is working.

</details>

### 7. [Optional] Final Cleanup

Are there any final changes you want to make? Any models you want to refactor? Any documentation you want to add?


<details>
  <summary>👉 What your dbt project should look like after this lab</summary>

  ```
  analysis/
  logs/
  macros/
  models/
  ├─ customers.sql
  ├─ orders.sql
  ├─ schema.yml
  ├─ sources.yml
  ├─ stg_ecomm__customers.sql
  ├─ stg_ecomm__deliveries.sql
  ├─ stg_ecomm__orders.sql
  seeds/
  snapshots/
  target/
  tests/
  .gitignore
  dbt_project.yml
  README.md
  ```
</details>

### 8. Merging the development branch back to the `main` branch

Now that you've done the lab the last thing to do is to commit your changes and merge the development branch (that you created at the beginning of the lab) to the `main` branch. Just click 'Merge this branch to main' in the top left corner after you've committed your changes and you're all set. Way to go! 💯


## Links and Walkthrough Guides

The following links will be useful for these exercises:

* [dbt Docs: Sources](https://docs.getdbt.com/docs/building-a-dbt-project/using-sources/)
* [dbt Docs: Documenting Models and Sources](https://docs.getdbt.com/docs/building-a-dbt-project/documentation/)
