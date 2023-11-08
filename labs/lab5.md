## Lab 5: Snapshots and Seeds

❗Remember to create a development branch `lab-5` at the beginning of the lab and at the end commit your changes to it and then merge the branch back to `main`.

### Kick-off discussion

* Are there any tables at your company that would benefit from being snapshotted?
* Are there any instances where having a snapshot table would have solved a problem at your company?
* Share some of your best `case when` horror stories.
* Are there any at your company that would benefit from a seed file?

### 1. Snapshot the customers table

Our application doesn't keep track of changes to any of the tables. When a record is updated, the prior state is lost as far as the application is concerned. From an analytics point of view, the full history would be really beneficial.

Set up a snapshot model on the `customers` source table (not the model).

Things to think about:
* What type of snapshot strategy is best for this table?
* What database and schema should it get built in?

<details>
  <summary>👉 Section 1</summary>

  (1) Create a file in the `snapshots/` directory called `customers_snapshot.sql` that contains the following code (replace `<initials>` with your initials):
  ```sql
    {% snapshot customers_snapshot %}

    {{
        config(
        target_database='analytics',
        target_schema='snapshots_<initials>',
        unique_key='id',

        strategy='check',
        check_cols = 'all',
        )
    }}

    select
      *
    from {{ source('ecomm', 'customers') }}

    {% endsnapshot %}
  ```
  (2) Execute `dbt snapshot` in the console at the bottom of your screen to make sure your snapshot run correctly.
</details>

### 2. Snapshot the orders table

Similarly, we want a snapshot of the `orders` source table. Set another snapshot up for that table.

Things to think about:
* What type of snapshot strategy is best for this table?
* Should this snapshot get built in the same database and schema as the other snapshot?

<details>
  <summary>👉 Section 2</summary>

  (1) Create a file in the `snapshots/` directory called `orders_snapshot.sql` that contains the following code (again, replace `<initials>` with your initials)):
  ```sql
    {% snapshot orders_snapshot %}

    {{
        config(
        target_database='analytics',
        target_schema='snapshots_<initials>',
        unique_key='id',

        strategy='timestamp',
        updated_at='_synced_at',
        )
    }}

    select
      *
    from {{ source('ecomm', 'orders') }}

    {% endsnapshot %}
  ```
  (2) Execute `dbt snapshot` in the console at the bottom of your screen to make sure your snapshots run correctly.
</details>

### 3. Add the stores seed file to our project

There's a `store_id` column on the `orders` table that we haven't leveraged yet. It looks like it _should_ join to a stores table, but it doesn't seem to exist in our application database.

It turns out, the engineers haven't yet built that table.

Create a seed file with the store IDs and names. Add a number column to our `orders` model called `store_name`.

The store mappings are as follows:

* Store ID 1: New York
* Store ID 2: Los Angeles
* Store ID 3: Dallas

<details>
  <summary>👉 Section 3</summary>

  (1) Create a file in the `seeds/` directory called `stores.csv` that contains the following data:
  ```csv
    store_id,store_name
    1,New York
    2,London
    3,Tokyo
  ```
  (2) Add a `schema.yml` file in the `seeds/` directory and document your `stores` seed there (see [example](https://docs.getdbt.com/faqs/tests/testing-seeds#example))
  (3) Execute `dbt seed` in the console at the bottom of your screen to make sure your seed uploads correctly.
  (4) You can now reference that data as `{{ ref('stores') }}`. Add code in your `orders` model that adds a `store_name` column.
  (5) Execute `dbt run -s orders` to make sure your updates run successfully.
</details>

## Links and Walkthrough Guides

The following links will be useful for these exercises:

* [dbt Docs: Snapshots](https://docs.getdbt.com/docs/building-a-dbt-project/snapshots/)
* [dbt Docs: Seeds](https://docs.getdbt.com/docs/building-a-dbt-project/seeds/)
