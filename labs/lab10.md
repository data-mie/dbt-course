## Lab 10: The dbt Mesh architecture

### Kick-Off Discussion
* How would you describe the dbt Mesh architecture to a colleague?
* How has managing dependencies and collaboration across different technical teams been challenging in your organization?
* What do you think are the benefits of splitting dbt projects using vertical and horizontal strategies, and which strategy aligns best with your organization's structure?



1. Splitting the project
  * Split the project into two projects: `dbt_course_finance` and `dbt_course_ecommerce`
2. Add a `conversion_rates` mart model to the `dbt_course_finance` project
  * Update all downstream `stg_finance__conversion_rates_usd` references to `conversion_rates`
3. Add a model contract for the `conversion_rates` model
  * Enforce model contract in the YML
  * Try running the model. What happens?
  * Add data_types to the `conversion_rates` model columns
  * Look at the DDL for the `conversion_rates` model. Can you see the contract at play?
4. Make changes to the `conversion_rates` model and create a prerelease version
  * Make changes
  * Create a `v2` prerelease version (set `latest_version: 1`)
  * Run `conversion_rates` and everything downstream from it. What happens?
5. Release the `conversion_rates_v2` model as the latest version
  * Set `latest_version: 2`
  * Run `conversion_rates+` and everything downstream from it. What happens?
  * Update the `int_ecomm__orders_enriched` model for compatibility with the latest `conversion_rates_v2` model
  * Run `conversion_rates+` to make sure everything works

### 1. Define the split?

...

Things to think about:
* What kind of a project split makes most sense here?

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
