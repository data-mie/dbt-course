## Lab 10: Model governance and the dbt Mesh architecture

### Kick-Off Discussion
* How would you describe the dbt Mesh architecture to a colleague?
* How has managing dependencies and collaboration across different technical teams been challenging in your organization?
* What would be the right split of the course project into multiple projects?

### 1. Split the project

Your data organization has made the decision to split the monolithic project vertically by domain. The two domains in the current project are `finance` and `ecommerce`. So, your task is to split the project into two projects: `dbt_course_finance` and `dbt_course_ecommerce`. 

<details>
  <summary>👉 Section 1</summary>

  (1) Create a new `dbt_course_finance` subfolder in the project root directory and copy the `dbt_project.yml` to the new folder and update contents to reflect the new project

  (2) Move `finance` models into the new folder

  (3) Run `dbt run` in the `dbt_course_finance` subfolder to make sure everything works. If not, fix it!

  (4) Repeat steps 1-2 for the `dbt_course_ecommerce` project so that it includes `ecomm` and `stripe` models

  (5) Import the `dbt_course_finance` project into `dbt_course_ecommerce` project by adding it as a package and then running `dbt deps`:

  ```yml
  packages:
    - local: ../finance
    ...
  ```

  (6) Upgrade refs to cross-project refs in the `dbt_course_ecommerce` project: `{{ ref('dbt_course_finance', '<model-name>') }}`

  (7) Run `dbt run` in the `dbt_course_ecommerce` project. What happens?
</details>


### 2. Add a `conversion_rates` mart model to the finance project

Your finance team has asked you to create a new `conversion_rates` mart model in their project that will be used as a point of abstraction for currency conversions in downstream projects. The model is specified to contain USD currency conversion rates at a daily level. The model should be based on the `stg_finance__conversion_rates_usd` staging model.

<details>
  <summary>👉 Section 2</summary>

  (1) Add `models/marts/conversion_rates.sql` to the finance project

  ```sql
  with rates_usd as (
      select
          *
      from {{ ref('stg_finance__conversion_rates_usd') }}
  ),

  fields as (
      select
          ... -- TODO: Explicitly select the fields you need
      from rates_usd
  ),

  final as (
      select
          *
      from fields
  )

  select
      *
  from final
  ```

  (2) Update all downstream `stg_finance__conversion_rates_usd` refs to `conversion_rates`

  (3) Ensure the model runs `dbt run -s conversion_rates`
</details>

### 3. Add a model contract for the `conversion_rates` model

Now that you have the `conversion_rates` model as the point of abstraction for currency conversions, you want to make sure that the model doesn't change in a way that breaks downstream models. To do that, you need to add a model contract to the `conversion_rates` model and enforce it.


<details>
  <summary>👉 Section 3</summary>

  (1) Add a `models/marts/conversion_rates.yml` schema YML file to the finance project

  (2) Enforce the model contract in the YML

  ```yml
  version: 2

  models:
    - name: conversion_rates
      description: USD currency conversion rates at a daily level
      config:
        contract:
          enforced: true
  ```

  (3) Run the model using `dbt run -s conversion_rates`. What happens?

  (4) Add column data types to the `conversion_rates` model YML:

  ```yml
  version: 2

  models:
    - name: conversion_rates
      description: USD currency conversion rates at a daily level
      config:
        contract:
          enforced: true
      columns:
        - name: conversion_rate_id
          data_type: ...  # TODO: Add data_type

        - name: date_day
          data_type: ...  # TODO: Add data_type

        - name: currency
          data_type: ...  # TODO: Add data_type

        - name: rate_usd
          data_type: ...  # TODO: Add data_type
  ```

  (5) Run the model again and ensure it finishes OK. Look at the DDL in the debug logs. Can you see the contract at play?
</details>


### 4. Introduce breaking changes to the `conversion_rates` model

You've been asked to make some changes to the `conversion_rates` model. The model is to be generalized for currency conversions between two arbitrary currencies. The model needs to contain the following columns: `date_day`, `source_currency`, `target_currency` and `rate`. The changes are breaking and you want to make sure that you don't break downstream models. To do that, you want to introduce a new version of the `conversion_rates` model and give downstream models time to migrate to the new version before you release it as the latest version.

<details>
  <summary>👉 Section 4</summary>

  (1) Rename the `conversion_rates` model to `conversion_rates_v1` in the finance project

  (2) Add `v1` version to the `conversion_rates` schema YML and set the latest version to `1`

  ```yml

  version: 2

  models:
    - name: conversion_rates
      latest_version: 1
      description: USD currency conversion rates at a daily level
      config:
        contract:
          enforced: true
      columns:
        ...
      versions:
        - v: 1
  ```

  (3) Create the new generalized version of the `conversion_rates` model in `models/marts/conversion_rates_v2.sql`:

  ```sql
  with rates_usd as (
      select
          *
      from {{ ref('stg_finance__conversion_rates_usd') }}
  ),

  fill_usd as (
      select
          date_day,
          currency,
          rate_usd
      from rates_usd

      union all

      select distinct
          date_day,
          'USD' as currency,
          1 as rate_usd
      from rates_usd
  ),

  fields as (
      select
          date_day,
          currency as source_currency,
          'USD' as target_currency,
          rate_usd as rate
      from fill_usd
  ),

  final as (
      select
          {{ dbt_utils.generate_surrogate_key(["date_day", "source_currency", "target_currency"]) }} as conversion_rate_id,
          *
      from fields
  )

  select
      *
  from final
  ```

  (4) Run the model using `dbt run -s conversion_rates`. What happens?

  (5) Switch to the `dbt_course_ecommerce` project and ensure that all the models are still running OK

</details>

### 5. Release the prerelease version as the latest version

With all the consumers having had enough time to migrate to the prerelease version of the `conversion_rates` model, you're ready to release the `v2` version as the latest version. You're tasked with making sure that the release goes smoothly and doesn't break any downstream models.

<details>
  <summary>👉 Section 5</summary>

  (1) Set `latest_version: 2` in the `conversion_rates` schema YML in the finance project

  (2) In the `dbt_course_ecommerce` project, run `dbt run -s conversion_rates+` to run the model and everything downstream from it. What happens?

  (3) Update any models that are broken by the new version of the `conversion_rates` model

  (4) Run `dbt run -s conversion_rates+` again to make sure everything works

</details>


<details>
  <summary>👉 What your dbt folder hierarchy may look like after this lab</summary>

  ```
  .
  ├── ecommerce/
  │   ├── macros/
  │   │   └── ...
  │   ├── models/
  │   │   ├── marts/
  │   │   │   └── ...
  │   │   └── staging/
  │   │       ├── ecomm/
  │   │       │   └── ...
  │   │       └── stripe/
  │   │           └── ...
  │   ├── dbt_project.yml
  │   └── packages.yml
  └── finance/
      ├── macros/
      │   └── ...
      ├── models/
      │   ├── marts/
      │   │   └── ...
      │   └── staging/
      │       └── finance/
      │           └── ...
      ├── dbt_project.yml
      └── packages.yml
  ```
</details>

## Links and Walkthrough Guides

The following links will be useful for these exercises:

* [dbt Blog: What is data mesh? The definition and importance of data mesh](https://www.getdbt.com/blog/what-is-data-mesh-the-definition-and-importance-of-data-mesh)
* [dbt Docs: Deciding how to structure your dbt Mesh](https://docs.getdbt.com/guides/best-practices/how-we-mesh/mesh-2-structures)
* [dbt Docs: Implementing your mesh plan](https://docs.getdbt.com/guides/best-practices/how-we-mesh/mesh-3-implementation)
