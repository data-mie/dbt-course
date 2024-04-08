## Lab 9: Snowflake Specifics in dbt

❗Remember to create a development branch `lab-9` at the beginning of the lab and at the end commit your changes to it and then merge the branch back to `main`.

### Kick-Off Discussion
* How much of what we just discussed is already in place at your company?
* How much of what we just discussed would be useful to implement at your company?
* What would be the right fields to cluster by in the `customers` model?
* What would be the right fields to cluster by in the `orders` model?

### 1. Run the orders model with a larger warehouse.

Despite making the `orders` model incremental, it's still taking too long to build. Add a configuration to the orders model that has it run with the larger `COMPUTE_WH_M` warehouse.

Things to think about:
* How do you verify that it's actually building with the new warehouse setting?

<details>
  <summary>👉 Section 1</summary>

  (1) Change the config in our `orders` model by adding the following:
  ```
  snowflake_warehouse='COMPUTE_WH_M'
  ```
  (2) Execute `dbt run -s orders`. Can you see your query in the Snowflake query history with the larger warehouse?

</details>

### 2. Add query tags to all dbt models

Because dbt queries can come from a long-list of users (all of you), we want to add a query tag `dbt_run` to all queries executed by dbt.

Add the query tag to your project and then verify that it's working.

<details>
  <summary>👉 Section 2</summary>

  (1) To add this config to all our models, we'll want to make the change in our `dbt_project.yml` file. We need it to be under the `models` key:
  ```yml
  models:
    +query_tag: 'dbt_run'
  ```
  (2) Execute `dbt run`. Can you see the query tags in Snowflake?

</details>


### 3. Calculating daily order totals using dynamic tables

We want to calculate the total amount of orders placed each day. We want to make this calculation dynamic so that we don't need to run the dbt model every time we want the latest data. To achieve this, we'll create a new model `daily_orders` that uses the `dynamic_table` materialization. But first, we need to clone the `RAW.ECOMM.ORDERS` table to our development schema so that we can emulate new orders being placed without affecting the production data.

<details>
  <summary>👉 Section 3</summary>

  (1) Create a zero copy clone of the `RAW.ECOMM.ORDERS` table in your development schema:
  ```sql
  create table analytics.dbt_<first_initial><last_name>.raw_orders clone raw.ecomm.orders;
  ```

  (2) Create a new model `daily_orders` that calculates the total amount of orders placed each day. Use the `dynamic_table` materialization:

  ```sql
  {{
      config(
          materialized='dynamic_table',
          target_lag='1 minute',
          snowflake_warehouse='compute_wh'
      )
  }}

  -- Note that we're directly referring to the cloned table without using the source macro
  -- This is a bad practice and you should avoid it in your own projects
  -- In this case, we're doing it to simplify the lab
  with orders as (
      select
          *
      from analytics.dbt_<first_initial><last_name>.raw_orders
  ),

  daily_orders as (
      select
          created_at::date as order_date,
          count(*) as order_count
      from orders
      group by 1
  ),

  final as (
      select
          *
      from daily_orders
  )

  select
      *
  from final
  ```

  (3) Run the `daily_orders` model and verify that it's working as expected:
  ```bash
  dbt run -s daily_orders
  ```

  (4) Emulate a new order being placed by inserting a row into the `raw_orders` table. Note that since we're inserting into the cloned table, we're not affecting the production data.
  ```sql
  insert into analytics.dbt_<first_initial><last_name>.raw_orders (total_amount, created_at)
  select uniform(5, 100, random()), current_timestamp();
  ```

  (5) Verify that the new order is reflected in the `daily_orders` model. Is it showing up? If not, why?
  ```sql
  select
      *
  from analytics.dbt_<first_initial><last_name>.daily_orders
  order by order_date desc
  ```

  (6) Add a `total_amount` column to the `daily_orders` model and rerun the model. Can you see the new column? Why not? Fix it!
</details>

### 4. Final Cleanup

The `daily_orders` dynamic table model is being automatically updated every minute and that would keep the warehouse running 24/7. Your task is to delete the `daily_orders` table to avoid incurring unnecessary costs.

<details>
  <summary>👉 Section 4</summary>

  (1) Drop the `daily_orders` table:
  ```sql
  drop table analytics.dbt_<first_initial><last_name>.daily_orders;
  ```
</details>

## Links and Walkthrough Guides

The following links will be useful for these exercises:

* [dbt Docs: Configuring Incremental Models](https://docs.getdbt.com/docs/building-a-dbt-project/building-models/configuring-incremental-models/)
* [dbt Discourse: On the limits of incrementality](https://discourse.getdbt.com/t/on-the-limits-of-incrementality/303)
