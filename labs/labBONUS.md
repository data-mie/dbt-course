## BONUS Lab: Recursive CTEs

### 1. Add a new column to our `orders` model that represents how many times an order has been re-ordered

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
  <summary>👉 Section 1</summary>

  This one is quite complicated, so bear with me here. I'd highly suggest doing it as a group.

  (1) We need to first construct a query that tells us which orders came from an original order. We'll start our recursive CTE with something like this:
  ```sql
    select
      reordered_from_id as order_id,
      id as reorder_id
    from {{ source('ecomm', 'orders') }}
    where reordered_from_id is not null
  ```
  This gives us a column for wherer an order originated, and a column for the orders that it directly created.

  (2) The 'recursive' part of the CTE then needs to replace the second column with any orders that the initial re-order created. We then get something like:
  ```sql
    with recursive reorders as (

        select
          reordered_from_id as order_id,
          id as reorder_id
        from {{ source('ecomm', 'orders') }}
        where reordered_from_id is not null

        union all

        select
          reorders.order_id,
          orders.id as reorder_id
        from reorders
        left join {{ source('ecomm', 'orders') }} as orders
            on reorders.reorder_id = orders.reordered_from_id
        where orders.id is not null

    )

    select *
    from reorders
   ```
   We now have a table that has a record for every reorder that has been produced by an original order, even if that reorder was down the 'chain' of orders.

   (3) Finally, we simply need to group by the `order_id` and count how many orders were produced. Replace the final select statement with the following:
   ```sql
    select
      order_id,
      count(*) as count_reorders_generated
    from reorders
    group by 1
  ```
</details>

## Links and Walkthrough Guides

The following links will be useful for these exercises:

* [Snowflake Docs: Recursive CTEs](https://docs.snowflake.com/en/user-guide/queries-cte.html#recursive-ctes-and-hierarchical-data)
