# Pre-Course Work

The goal of this pre-work is to get each student set up in Snowflake and dbt Core, as well as create the beginnings of the dbt project that we will develop over the course.

If at any point you have any questions or something doesn't appear to be working as you'd expect, please reply to the introduction email and I'll make sure we get it all sorted out.

## 1. Set up Snowflake account

You will have received your Snowflake user name in the introduction message. Once you log into Snowflake, you should see the Snowflake editor (**if prompted, select Classic UI instead of Snowsight**). Run the following query to verify you have the correct permissions:

```sql
use role <role>;            -- Replace <role> with role name from the welcome email
use warehouse <warehouse>;  -- Replace <warehouse> with warehouse name from the welcome email

select
    *
from raw.ecomm.orders
limit 100;
```

If you see orders data, you're good to go!

## 2. Create your dbt development environment

If you already have a local dbt development environment set up, please note that the version of dbt we'll be using during this course may differ from the version you have in your organization. Therefore, it's necessary to create an isolated development environment specifically for this course.

To ensure a consistent learning experience, please follow these steps to set up your isolated environment:

1. Create a folder for the course project (e.g., `<your-home-folder>/projects/dbt-course`)
2. Initialize a new git repository in the course project folder: `git init`
3. Create a Python virtual environment in the course project folder: `python3 -m virtualenv venv`
4. Activate the virtual environment: `source venv/bin/activate`
    * Note that you have to reactivate the virtual environment every time you start working on the project
5. Install dbt Core with the Snowflake adapter: `python -m pip install dbt-snowflake==1.5`
6. Add a Snowflake connection profile to your `<your-home-folder>/.dbt/profiles.yml`:

```yml
dbt_course:
  outputs:
    dev:
      account: <account>                        # Replace <account> with account name from the welcome email
      database: <database>                      # Replace <database> with database name from the welcome email
      schema: <schema>                          # Replace <schema> with schema name from the welcome email
      role: <role>                              # Replace <role> with role name from the welcome email
      warehouse: <warehouse>                    # Replace <warehouse> with warehouse name from the welcome email
      user: <user>                              # Replace <user> with user name from the welcome email
      password: <password>                      # Replace <password> with password from the welcome email
      threads: 4
      type: snowflake
  target: dev
```
7. Create a `dbt_project.yml` file in the course project folder:

```yml
# Name your project! Project names should contain only lowercase characters
# and underscores. A good package name should reflect your organization's
# name or the intended use of these models
name: 'dbt_course'
version: '1.0.0'
config-version: 2

# This setting configures which "profile" dbt uses for this project.
profile: 'dbt_course'

# These configurations specify where dbt should look for different types of files.
# The `source-paths` config, for example, states that models in this project can be
# found in the "models/" directory. You probably won't need to change these!
model-paths: ["models"]
analysis-paths: ["analyses"]
test-paths: ["tests"]
seed-paths: ["seeds"]
macro-paths: ["macros"]
snapshot-paths: ["snapshots"]

target-path: "target"  # directory which will store compiled SQL files
clean-targets:         # directories to be removed by `dbt clean`
  - "target"
  - "dbt_packages"


# Configuring models
# Full documentation: https://docs.getdbt.com/docs/configuring-models

# In this example config, we tell dbt to build all models in the example/ directory
# as tables. These settings can be overridden in the individual model files
# using the `{{ config(...) }}` macro.
models:
  dbt_course:
    # Applies to all files under models/
    +materialized: view
```
8. Create a `.gitignore` file in the course project folder to prevent unnecessary files to be committed to the git repository:

```
venv/
target/
logs/
dbt_packages/
```
9. Stage your changes: `git add dbt_project.yml .gitignore`
10. Do the initial commit: `git commit -m "Initialize dbt project"`
11. Rename the root branch as `main`: `git branch -M main`

And that's it, now you have a virtual environment fully configured and ready for development. Please ensure that you use this isolated development environment for the duration of the course to avoid any compatibility issues and ensure a smooth learning experience.

## 3. Create your first models

The final step is to create your first dbt model. We're going to create a basic `customers` model, with data from our customers and orders data. To do so, complete the following steps:

1. Create an empty `models/` folder in the course project folder: `mkdir models`
2. Create a `customers.sql` file in the `models/` folder:

```sql
with orders as (
    select
        id as order_id,
        customer_id,
        created_at as ordered_at
    from raw.ecomm.orders
), 

customers as (
    select
        id as customer_id,
        first_name,
        last_name,
        email,
        address,
        phone_number
    from raw.ecomm.customers
),

customer_metrics as (
    select
        customer_id,
        count(*) as count_orders,
        min(ordered_at) as first_order_at,
        max(ordered_at) as most_recent_order_at
    from orders
    group by 1

),

joined as (
    select
        customers.*,
        coalesce(customer_metrics.count_orders,0) as count_orders,
        customer_metrics.first_order_at,
        customer_metrics.most_recent_order_at
    from customers
    left join customer_metrics on (
        customers.customer_id = customer_metrics.customer_id
    )
)

select
    *
from joined
```

3. Finally, we want to build this model as an object in our database. Execute `dbt run` in your terminal and you should see your new `customers` model being built.

## 4. Wrapping up

Now that you have added the `customers` model you need to commit your changes to the git repository:

1. Stage the `customers` model SQL file: `git add models/customers.sql`
2. Do the commit: `git commit -m "Add customers model"`

You've now written your first dbt model and have completed the pre-course requirements. I'm looking forward to teaching all of you in the upcoming course!
