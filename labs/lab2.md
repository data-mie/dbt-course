## Lab 2: Jinja and Testing

## Kick-off Discussion Questions

1. What are instances where more testing would have been useful at your company? What was the issue? What test would you have added?
2. What are some examples of SQL that you've written recently that might benefit from using Jinja?

### 0. Delete the example folder.

When setting up your project, a `models/example/` folder was created with models and tests. If you haven't already, please delete it now or it will pose problems during this lab.

### 1. Make sure our models have primary keys

We've got two models, `orders` and `customers`. Each should have a primary key. We want to make sure that the primary keys are unique and not null.

Things to think about:
* If the tests fail, is there a problem with our query?

<details>
  <summary>👉 Section 1</summary>

  (1) Add `unique` and `not_null` tests to the `schema.yml` files. For the `orders` table, it will contain the following information:
  ```yml
  version: 2

  models:
    - name: orders
      columns:
        - name: order_id
          tests:
            - unique
            - not_null
  ```
  (2) Execute `dbt test` in the console at the bottom of your screen to make sure all the tests pass.
</details>

### 2. Add columns to your `customers` model that contain how many orders the customer had in the last 30, 90 and 360 days.

More work for our retention team. They want to easily be able to see how order patterns affect customer behaviour. They want to be able to easily write a query that would tell them how many customers have more than 5 orders in the last 30 days.

Things to think about:
* Are there ways that Jinja could be helpful here?

<details>
  <summary>👉 Section 2</summary>

  (1) Given the SQL for the three columns will be _almost_ identical, we could use a Jinja `for` loop here. Add the following SQL to your `customer_metrics` CTE:
  ```sql
  {% for days in [30,90,360] %}
  count(case when ordered_at > current_date - {{ days }} then 1 end) as count_orders_last_{{ days }}_days
  {% if not loop.last %} , {% endif %}
  {% endfor %}
  ```
  (2) Add your three new columns to the `joined` CTE.
  (3) Execute `dbt run` in the console at the bottom of your screen to make sure everything runs successfully.
</details>

### 3. Add a test to ensure all the delivery time columns are greater than zero (if not null)

In the last lab, we added two columns to each of the `orders` and `customers` models. In theory, when populated, they should always be greater than zero. We'll need to write a custom schema test that ensures that's always the case.

<details>
  <summary>👉 Section 3</summary>

  (1) Given this feels like a test that will be broadly re-usable, we'll likely want to create a custom schema test. Create a new file in the `macros/` directory called `test_greater_than_zero.sql` that contains the following code:
  ```sql
  {% test greater_than_zero(model, column_name) %}

  select
      *
  from {{ model }}
  where {{ column_name }} <= 0

  {% endtest %}
  ```
  (2) Add the tests to your `schema.yml` file. For the column `delivery_time_from_collection` in the `orders` model, it would look as follows:
  ```yml
    - name: orders
      columns:
        - name: delivery_time_from_collection
          tests:
            - greater_than_zero
  ```
  (3) Execute `dbt test` in the console at the bottom of your screen to make sure all the tests pass.
</details>

### 4. Add a test to ensure that the number of orders in the last 90 days from our `customers` table doesn't exceed the total number of orders in our `orders` table.

Having added the new columns in step 2, we want to double-check that the sum of the column on the `customers` model doesn't exceed the total number of orders in our `orders` model.

Given the specificity of this test, we likely don't want to write a custom schema test. Could we use a data test to do it?

<details>
  <summary>👉 Section 4</summary>

  (1) Create a new file in the `tests/` directory called `count_orders_check.sql` that contains the following SQL:
  ```sql
  with orders as (
      select
          count(*) as orders_count
      from {{ ref('orders') }}
  ),

  customers as (
      select
          sum(count_orders_last_90_days) as customers_count
      from {{ ref('customers') }}
  ),

  joined as (
      select
          *
      from orders
      cross join customers
      where customers_count > orders_count
  )

  select
      *
  from joined
  ```
  (2) Execute `dbt test` in the console at the bottom of your screen to make sure all the tests pass.
</details>


<details>
  <summary>👉 What your dbt project should look like after this lab</summary>

  ```
  analysis/
  data/
  labs/
  ├─ ...
  macros/
  ├─ test_greater_than_zero.sql
  models/
  ├─ customers.sql
  ├─ orders.sql
  ├─ schema.yml
  ├─ sources.yml
  ├─ stg_ecomm__customers.sql
  ├─ stg_ecomm__deliveries.sql
  ├─ stg_ecomm__orders.sql
  models/
  pre-course/
  ├─ ...
  snapshots/
  tests/
  ├─ count_orders_check.sql
  .gitignore
  README.md
  dbt_project.yml
  ```
</details>

## Links and Walkthrough Guides

The following links will be useful for these exercises:

* [dbt Docs: Tests](https://docs.getdbt.com/docs/building-a-dbt-project/tests)
* [dbt Docs: Jinja & Macros](https://docs.getdbt.com/docs/building-a-dbt-project/jinja-macros/)
* [dbt Docs: Custom schema/generic tests](https://docs.getdbt.com/docs/guides/writing-custom-schema-tests/)
* [dbt Docs: Data/singular tests](https://docs.getdbt.com/docs/building-a-dbt-project/tests/#singular-tests)
* [Jinja Template Designer Docs](https://jinja.palletsprojects.com/en/3.0.x/templates/)
