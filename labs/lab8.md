## Lab 8: Incremental Models

❗Remember to create a development branch `lab-8` at the beginning of the lab and at the end commit your changes to it and then merge the branch back to `main`.

### 1. Make the orders model incremental

We've had a huge spike in order volumes because of Covid and as a result our `orders` model is taking longer and longer to build.

Make the orders model incremental, without a primary key and without a lookback period, i.e. just insert new orders that were ordered since the last run.

<details>
  <summary>👉 Section 1</summary>

  (1) In our orders model, find the CTE where we select from the orders staging model. Why do we add the filter in this CTE? In the CTE, add the `is_incremental()` filter:
  ```sql
  {% if is_incremental() %}
  where ordered_at > (select max(ordered_at) from {{ this }})
  {% endif %}
  ```
  (2) At the top of our model, add a configuration that tells dbt that this model should be 'incremental':
  ```
  {{ config(materialized='incremental') }}
  ```
  (3) Run `dbt run -s orders` and inspect the compiled SQL that is being executed. Does it look like it's working correctly? You should see the temp table being created and then an insert. (You might need to run it twice if it's being built as a table for the first time.)

</details>

### 2. Check how late orders arrive in our system

Our engineers have just discovered a bug that causes some orders to arrive in the warehouse much later than they should. As a result, we're now worried about our incremental model missing data.

Write a query to check how many days back we need to look back in order to ensure our model catches 99% of new orders. You should compare the `created_at` and `_synced_at` columns.

<details>
  <summary>👉 Section 2</summary>

  (1) To check this, we need to inspect what the typical difference is between the two columns:
  ```sql
  select
    datediff('day', created_at, _synced_at) as days_lag,
    count(*)
  from raw.ecomm.orders
  group by 1
  ```
  (2) We can see as a result of that query that all orders show up within 3 days.

</details>

### 3. Re-factor the incremental model to account for a lookback window

Based on your findings in step 2, refactor the incremental model to ensure we always re-process 99% of orders. As we'll now be re-processing data, we'll need to add a unique key so that records do not get duplicated.

<details>
  <summary>👉 Section 3</summary>

  (1) In our orders model, we need to alter our `is_incremental()` section to account for a lookback of three days:
  ```sql
  {% if is_incremental() %}
  where ordered_at > (select dateadd('day', -3, max(ordered_at)) from {{ this }})
  {% endif %}
  ```
  (2) At the top of our model, we also now need to use a `unique_key`:
  ```
  {{ config(materialized='incremental', unique_key='order_id') }}
  ```
  (3) Run `dbt --debug run -s orders` and inspect the compiled SQL that is being executed. Does it look like it's working correctly? You should now see a merge statement instead of an insert.

</details>


## Links and Walkthrough Guides

The following links will be useful for these exercises:

* [dbt Docs: Configuring Incremental Models](https://docs.getdbt.com/docs/building-a-dbt-project/building-models/configuring-incremental-models/)
* [dbt Discourse: On the limits of incrementality](https://discourse.getdbt.com/t/on-the-limits-of-incrementality/303)
