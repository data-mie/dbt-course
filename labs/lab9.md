## Lab 9: Snowflake Specifics in dbt

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


### 3. Add a `cluster_by` config to the orders model

While our orders model now builds quickly, it's still very slow to query.

Add a `cluster_by` config to the `orders` model, based on what you think the most common query pattern will be.

<details>
  <summary>👉 Section 3</summary>

  (1) I'm going to assume that filtering by the `ordered_at` is going to be the most common query pattern. We're therefore going to cluster by that column, by adding the following line to the config in the `orders` model:
  ```
  cluster_by=['ordered_at']
  ```
  (2) Execute `dbt run -s orders` to make sure everything works correctly. Can you see the 'cluster by' section of the logs?

</details>

## Links and Walkthrough Guides

The following links will be useful for these exercises:

* [dbt Docs: Configuring Incremental Models](https://docs.getdbt.com/docs/building-a-dbt-project/building-models/configuring-incremental-models/)
* [dbt Discourse: On the limits of incrementality](https://discourse.getdbt.com/t/on-the-limits-of-incrementality/303)
