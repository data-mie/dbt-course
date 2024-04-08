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


### 3. Create a zero copy clone of the production database

Building the entire project from scratch in your development environment using `dbt run` may take a long time. To get up and running quickly, we can create a zero copy clone of the production database. This will allow us to build our development models on top of production models without actually affecting the production data.

<details>
  <summary>👉 Section 3</summary>

    (1) Drop your existing development schema and create a zero copy clone of the production database by running the following command:
    ```sql
    drop schema analytics.dbt_stumelius cascade;
    create schema if not exists analytics.dbt_stumelius clone analytics.production;
    ```
    (2) Run the `customers` model to verify:
    ```bash
    dbt run -s customers
    ```
</details>


## Links and Walkthrough Guides

The following links will be useful for these exercises:

* [dbt Docs: Configuring Incremental Models](https://docs.getdbt.com/docs/building-a-dbt-project/building-models/configuring-incremental-models/)
* [dbt Discourse: On the limits of incrementality](https://discourse.getdbt.com/t/on-the-limits-of-incrementality/303)
