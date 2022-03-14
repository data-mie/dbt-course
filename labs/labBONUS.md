## BONUS Lab: Semi-Structured Data and Recursive CTEs

### Kick-off questions

* What semi-structured data exists within your company?
* How is that data being transformed currently?

### 1. Create a staging model for the payments data

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
  <summary>👉 Section 1</summary>

  (1) Add a new source for the Stripe data.

  (2) Create a new file `stg_stripe__payments.sql` in our `models/` directory.

  (3) Pull out the necessary columns from the JSON. Write a query around the following column definitions:
  ```sql
    json_data:order_id as order_id,
    json_data:id as payment_id,
    json_data:method as payment_type,
    json_data:amount::int / 100.0 as payment_amount,
    json_data:created_at::timestamp as created_at
  ```

  (4) Execute `dbt run -s stg_stripe__payments` to make sure everything is working correctly.

</details>

### 2. Write a query that provides a record for each zipcode

As part of the payments data work, we also received a dataset with information about US zipcodes. Again, this data has been provided to us as a single JSON object and we want to unnest it so that each record contains a zipcode and relevant information about that zipcode.

Write a query, using a `lateral flatten`, that contains a record for each zipcode in our new dataset.

The data for this exercise can be found at `raw.geo.countries`.

<details>
  <summary>👉 Section 2</summary>

  (1) In a new SQL query, inspect the format of the table by running `select * from raw.geo.countries`.

  (2) Let's 'unnest' the `states` array by adding a `lateral flatten` to the query:
  ```sql
    select
        country,
        s.value:state as state,
        s.value:zipcodes as zipcodes
    from raw.geo.countries
    left join lateral flatten (input => states) as s
  ```
  We now have a record for each state, which we can see has another array in it called `zipcodes`.

  (3) Let's 'unnest' the `zipcodes` array by adding another `lateral flatten`:
  ```sql
    select
        country,
        s.value:state as state,
        c.value:zipcode as zipcode,
        c.value:city as city
    from raw.geo.countries
    left join lateral flatten (input => states) as s
    left join lateral flatten (input => s.value:zipcodes) as c
  ```

  (4) It looks like some of our columns aren't coming through as the correct data type. Let's cast them to strings:
  ```sql
    select
        country,
        s.value:state::varchar as state,
        c.value:zipcode::varchar as zipcode,
        c.value:city::varchar as city
    from raw.geo.countries
    left join lateral flatten (input => states) as s
    left join lateral flatten (input => s.value:zipcodes) as c
  ```
  We should now have a complete query.

</details>

### 3. Add a new column to our `orders` model that represents how many times an order has been re-ordered

A few months ago, our engineers added the ability in our application to simply 're-order' a prior order. The ID of the order that was 're-ordered' exists on our source orders data.

Write a query, using a recursive CTE, that shows how many times a given order was 're-ordered'. For the following 'chain' of orders, we would expect the following output:

| order_id | reordered_from_id | reordered_count |
|----------|-------------------|-----------------|
| 1        |                   | 4               |
| 2        | 1                 | 3               |
| 3        | 2                 | 0               |
| 4        | 2                 | 1               |
| 5        | 4                 | 0               |

Order 1 generated 4 downstream orders. It generated order 2, which in turn generated orders 3 and 4, the latter of which generated order 5, for a total of 5 (2,3,4,5)
Order 2 generated 3 downstream orders. It generated order 3 and 4, the latter of which generated order 5, for a total of 3 (3,4,5).
Order 3 had no downstream orders.
Order 4 generated 1 downstream order. It generated order 5, for a total of 1 (5).
Order 5 had no downstream orders.

<details>
  <summary>👉 Section 3</summary>

  This one is quite complicated, so bear with me here. I'd highly suggest doing it as a group.

  (1) We need to first construct a query that tells us which orders came from an original order. We'll start our recursive CTE with something like this:
  ```sql
    select reordered_from_id as order_id, order_id as reorder_id
    from {{ ref('stg_ecomm__orders') }}
    where reordered_from_id is not null
  ```
  This gives us a column for wherer an order originated, and a column for the orders that it directly created.

  (2) The 'recursive' part of the CTE then needs to replace the second column with any orders that the initial re-order created. We then get something like:
  ```sql
    with recursive reorders as (

        select reordered_from_id as order_id, order_id as reorder_id
        from {{ ref('stg_ecomm__orders') }}
        where reordered_from_id is not null

        union all

        select reorders.order_id, orders.order_id as reorder_id
        from reorders
        left join {{ ref('stg_ecomm__orders') }} as orders
            on reorders.reorder_id = orders.reordered_from_id
        where orders.order_id is not null

    )

    select *
    from reorders
   ```
   We now have a table that has a record for every reorder that has been produced by an original order, even if that reorder was down the 'chain' of orders.

   (3) Finally, we simply need to group by the `order_id` and count how many orders were produced. Replace the final select statement with the following:
   ```sql
    select order_id, count(*) as count_reorders_generated
    from reorders
    group by 1
  ```
</details>

## Links and Walkthrough Guides

The following links will be useful for these exercises:

* [Snowflake Docs: Querying Semi-Structured Data](https://docs.snowflake.com/en/user-guide/querying-semistructured.html)
* [Snowflake Docs: Recursive CTEs](https://docs.snowflake.com/en/user-guide/queries-cte.html#recursive-ctes-and-hierarchical-data)
