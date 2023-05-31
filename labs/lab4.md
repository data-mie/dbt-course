## Lab 4: Window Functions, Calendar Spines, and Semi-Structured Data

❗Remember to create a development branch `lab-4` at the beginning of the lab and at the end commit your changes to it and then merge the branch back to `main`.

### 1. Add a `days_since_last_order` column to the `orders` model.

It's useful for analysis to know how many days had passed between an order and the prior order (for a given customer).

Using a window function, add a column `days_since_last_order` to the `orders` model.

<details>
  <summary>👉 Section 1</summary>

  (1) To calculate `days_since_last_order` we need to add the following SQL (or similar depending on what you've named columns) to our `orders` model. It finds the prior order for a customer and calculates the difference in days between the two `ordered_at` values:
  ```sql
    datediff('day', lag(ordered_at) over (partition by customer_id order by ordered_at), ordered_at)
  ```
  (2) Execute `dbt run -s orders` to make sure your model runs successfully.
</details>

### 2. Filter out employees from the orders and customers models

Employees get a discount from our ecommerce shop. While we're very happy for them to have that discount, we want to filter out all of their records from the warehouse.

If you haven't already, create a staging model for the customers data. In the staging model, filter out all emails for the domains `ecommerce.com`, `ecommerce.co.uk`, `ecommerce.ca`.

That filter should fix the customers data, but we still need to add a filter to the `orders` model. Filter out any employee orders.

<details>
  <summary>👉 Section 2</summary>

  (1) As discussed in the session, there are a number of different ways we could do this filter. In this instance we'll use `endswith`. Add the following filter to your customers model:
  ```sql
    where not (
      endswith(email,'ecommerce.com')
      or endswith(email,'ecommerce.ca')
      or endswith(email,'ecommerce.co.uk')
    )
  ```
  (2) Add the same filter to your `orders` model. Note that the `email` column isn't likely to already be there so you might need to join it in.
  (3) Execute `dbt run` to make sure your filters work.
</details>

### 3. Create a staging model for the payments data

We've recently integrated our payments data into Snowflake. The data comes as a JSON API response from the source system and we decided it would be easier to just put it in Snowflake in the same format.

The table can be found at `raw.stripe.payments`.

Create a staging model for the new payments data that includes the following fields:
* order_id
* payment_id
* payment_type
* payment_amount
* created_at

Things to think about:
* Does our new model need tests?
* Does every column have the correct datatype?

<details>
  <summary>👉 Section 3</summary>

  (1) Add a new `stripe` source with the `payments` table for the Stripe data in the `models/sources.yml` file

  (2) Create a new file `stg_stripe__payments.sql` in our `models/` directory.

  (3) Pull out the necessary columns from the JSON. Write a query around the following column definitions:
  ```sql
    json_data['order_id'] as order_id,
    json_data['id'] as payment_id,
    json_data['method'] as payment_type,
    json_data['amount']::int / 100.0 as payment_amount,
    json_data['created_at']::timestamp as created_at
  ```

  (4) Execute `dbt run -s stg_stripe__payments` to make sure everything is working correctly.

</details>

### 4. Write a query that provides a record for each zipcode

As part of the payments data work, we also received a dataset with information about US zipcodes. Again, this data has been provided to us as a single JSON object and we want to unnest it so that each record contains a zipcode and relevant information about that zipcode.

Write a query, using a `lateral flatten`, that contains a record for each zipcode in our new dataset.

The data for this exercise can be found at `raw.geo.countries`.

<details>
  <summary>👉 Section 4</summary>

  (1) In a new SQL query, inspect the format of the table by running `select * from raw.geo.countries`.

  (2) Let's 'unnest' the `states` array by adding a `lateral flatten` to the query:
  ```sql
    select
        country,
        state.value:state as state,
        state.value:zipcodes as zip_codes
    from raw.geo.countries
    left join lateral flatten (input => states) as state
  ```
  We now have a record for each state, which we can see has another array in it called `zipcodes`.

  (3) Let's 'unnest' the `zipcodes` array by adding another `lateral flatten`:
  ```sql
    select
        country,
        state.value:state as state,
        zip_code.value:zipcode as zip_code,
        zip_code.value:city as city
    from raw.geo.countries
    left join lateral flatten (input => states) as state
    left join lateral flatten (input => state.value:zipcodes) as zip_code
  ```

  (4) It looks like some of our columns aren't coming through as the correct data type. Let's cast them to strings:
  ```sql
    select
        country,
        state.value:state::varchar as state,
        zip_code.value:zipcode::varchar as zip_code,
        zip_code.value:city::varchar as city
    from raw.geo.countries
    left join lateral flatten (input => states) as state
    left join lateral flatten (input => state.value:zipcodes) as zip_code
  ```
  We should now have a complete query.

</details>

### 5. Create a `customers_daily` model

Because customers regularly change their addresses, our support team want to know what address a customer had in a system on a given day.

First, create a calendar spine using the dbt-utils package.

Then, create a model called `customers_daily` that uses our snapshot data and the calendar spine to have a record of what a customer looked like on each day since they were created.

**N.B.**: For the purposes of this exercise, given we don't have our own snapshot data, please use the following table for the snapshot data: `analytics.snapshots_prod.customers_snapshot`.

<details>
  <summary>👉 Section 5</summary>

  (1) Make sure there's a `packages.yml` file in the root directory of your project. If not, create the file and add `dbt_utils` and `dbt_date` dependencies:
  ```yaml
  packages:
    - package: dbt-labs/dbt_utils
      version: 1.0.0
    - package: calogica/dbt_date
      version: 0.7.2
  ```
  Make sure you run `dbt deps` so the packages are installed in your project.

  (2) Create a new model called `calendar.sql`. Add the following code to it to generate a calendar spine and replace `<current_date>` with the current date:
  ```sql
  {{ dbt_date.get_date_dimension('2020-01-01', '<current_date>') }}
  ```

  (3) Create a new model called `customers_daily.sql`. Add the following SQL:
  ```sql
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
  ```
  (4) Execute `dbt run -s +customers_daily` to make sure your models run successfully.
</details>

### 6. Write a query that shows rolling 7-day order volumes

You've had a request from the CEO to create a dashboard with the rolling 7-day order amounts. Because some days don't have orders, you think you'll need to use a calendar spine to create it.

Write a query that shows the number of orders on a rolling 7-day basis.

<details>
  <summary>👉 Section 6</summary>

  (1) Write a SQL query that joins our `orders` and `calendar` models on the `orders.ordered_at` and `calendar.date_day` columns.

  (2) Calculate the number of orders per `date_day`.

  (3) Use a window a function to calculate the rolling 7-day order volumes.
</details>

## Links and Walkthrough Guides

The following links will be useful for these exercises:

* [Snowflake Docs: Functions](https://docs.snowflake.com/en/sql-reference/functions-all.html)
* [Snowflake Docs: Window Functions](https://docs.snowflake.com/en/sql-reference/functions-analytic.html)
* [Snowflake Docs: Querying Semi-Structured Data](https://docs.snowflake.com/en/user-guide/querying-semistructured.html)
* [dbt Docs: Packages](https://docs.getdbt.com/docs/building-a-dbt-project/package-management/)
