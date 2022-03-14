## Lab 3: CTEs, Subqueries, and Query Optimization

### 1. Re-write the query using CTEs

You received a query from a colleague in the marketing department who was trying to pull some information from your warehouse. Unfortunately, they exclusively used subqueries and you want to clean it up before providing your feedback because you think it will be easier to read.

Create a new file for the following query and re-write it using CTEs instead of subqueries.

```sql
select
    customer_id,
    first_name,
    last_name,
    (select round(avg(total_amount),2) from {{ ref('orders') }} where orders.customer_id = customers.customer_id and ordered_at > current_date - 180) as avg_order_amount,
    (select count(*) from {{ ref('orders') }} where orders.customer_id = customers.customer_id and ordered_at > current_date - 180) as order_count
from {{ ref('customers') }}
where customer_id in (
  select
    distinct customer_id
  from {{ ref('orders') }}
  where ordered_at > current_date - 42
)
```
<details>
  <summary>👉 Section 1 (try first before opening this)</summary>

  (1) Create a file in the `models/` directory called `seven_week_active_customers.sql` and put the query above in it.
  (2) There are two bits that we feel we could re-factor into CTEs. The first is the subquery in the `where` clause. We can also join it instead of doing a `where customer_id in`. We can pull this out so that our file looks as follows:
  ```sql
  with customers as (
    select
      *
    from {{ ref('customers') }}
  ),

  seven_weeks as (
    select distinct
      customer_id
    from {{ ref('orders') }}
    where ordered_at > current_date - 42
  )

  select
      customers.customer_id,
      customers.first_name,
      customers.last_name,
      (select round(avg(total_amount),2) from {{ ref('orders') }} where orders.customer_id = customers.customer_id and ordered_at > current_date - 180) as avg_order_amount,
      (select count(*) from {{ ref('orders') }} where orders.customer_id = customers.customer_id and ordered_at > current_date - 180) as order_count
  from customers
  inner join seven_weeks on (customers.customer_id = seven_weeks.customer_id)
  ```
  (3) The second section we can pull out is the two metric columns that are calculated with subqueries. These can be done an aggregate and a join. It would leave our file as follows:
  ```sql
  with customers as (
    select
      *
    from {{ ref('customers') }}
  ),

  seven_weeks as (
    select distinct
      customer_id
    from {{ ref('orders') }}
    where ordered_at > current_date - 42
  ),
  
  half_year as (
    select
      customer_id,
      round(avg(total_amount),2) as avg_order_amount,
      count(*) as order_count
    from {{ ref('orders') }}
    where ordered_at > current_date - 180
    group by 1
  )

  select
      customers.customer_id,
      customers.first_name,
      customers.last_name,
      half_year.avg_order_amount,
      half_year.order_count
  from customers
  left join half_year on (customers.customer_id = half_year.customer_id)
  inner join seven_weeks on (customers.customer_id = seven_weeks.customer_id)
  ```
  (3) Execute `dbt run -s +seven_week_active_customers` to make sure your model runs successfully.
</details>

### 2. Break out the query into ephemeral models.

After reviewing the query, you think it would be useful to add it to your dbt project. However, you think part of the query is going to be re-usable elsewhere and want to break it up.

Move part of the query into another model. You won't want the new model to appear in the warehouse, so set it to be materialized as ephemeral.

Things to think about:

* What section of the query is most suitable to be split out?
* Are there any tests you should apply to the new ephemeral model?

<details>
  <summary>👉 Section 2</summary>

  (1) Create two new `.sql` files for the CTEs and move the SQL from the CTEs across into them.

  (2) Re-factor the initial file by replacing the code in the CTEs with `select *` queries from the new models.

  (3) Add a config to the two new models so that they get `materialized` as `ephemeral`.

  (4) Execute `dbt run -s +seven_week_active_customers` to make sure your model runs successfully.
</details>

## Links and Walkthrough Guides

The following links will be useful for these exercises:

* [dbt Docs: Ephemeral materialization](https://docs.getdbt.com/docs/building-a-dbt-project/building-models/materializations/#ephemeral)
