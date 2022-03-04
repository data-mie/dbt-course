# Pre-Course Work

The goal of this pre-work is to get each student set up in Snowflake and dbt Cloud, as well as create the beginnings of the dbt project that we will develop over the course.

If at any point you have any questions or something doesn't appear to be working as you'd expect, please reply to the introduction email and I'll make sure we get it all sorted out.

## 1. Set up Snowflake account

You will have received your Snowflake user name in the introduction message. Once you log into Snowflake, you should see the Snowflake editor. Run the following query to verify you have the correct permissions (use the ):

```sql
use role transformer;
use warehouse compute_wh;

select
    *
from raw.ecomm.orders
limit 100;
```

If you see data, you're good to go.

## 2. Set up dbt Cloud account

You will also have received an invite for the dbt Cloud project. Click on the link in the email and fill out the onboarding form with your personal information.

## 3. Configure dbt Cloud

For the purposes of the course, you'll be creating your own dbt Cloud project. To do so, follow the following steps:

1. Click on the menu in the top left corner and select 'Account Settings'.
2. Click on the 'Projects' tab on the left and select 'New Project' in the top right corner.
3. Click 'Begin'.
4. Name the project 'dbt training - (first initial) (last name)'. For Simo Tumelius, this would be 'dbt training - S Tumelius'. Click Continue.
5. Click 'Snowflake'.
6. Under 'Snowflake Settings', fill out the form with the following details:
    - Account: wpa36811
    - Role: transformer
    - Database: analytics
    - Warehouse: compute_wh
7. Under 'Development Credentials', fill out the form with the following details:
    - Auth Method: Username & Password
    - Username: Your Snowflake username
    - Password: Your Snowflake password
    - Schema: dbt_(first initial)(last name), i.e. for Simo Tumelius it would be dbt_stumelius
    - Target: dev
    - Threads: 2
8. Click 'Test'. If you the tests pass, click 'Continue'. If the tests fail, return to the prior two steps and make sure all the details are entered correctly.
9. On the repository page, add a repository from 'Managed'. This will prompt dbt Cloud to create a git repository for you.
10. Name the repository 'dbt_training_(firstinitial)(lastname)' and click 'Create'. For Simo Tumelius, this would be 'dbt_training_stumelius'. You should receive a success message on the page. Click 'Continue'.
11. You'll be prompted to invite users. Click 'Skip & Complete' at the top of the page.

## 4. Initialize your dbt project

After configuring the previous steps, you should be brought back to the main page. You should be prompted to 'Start Developing'. Click that button. If you do not see the button, click on the hamburger menu in the top left and select 'Develop'. Once you're brought to the IDE, it will take a few seconds to set everything up.

There will be a big green button in the top left corner that says 'initialize your project'. Click that button. dbt Cloud will then create a template dbt Project for you to start developing.

To test that everything is set up properly, we're going to try building some dbt models. There are two example models in the project by default.

Type in 'dbt run' in the bar at the bottom of your screen (if it isn't already there by default) and click enter. You should see two models, `my_first_dbt_model` and `my_second_dbt_model`, complete successfully.

Congratulations! You've just run dbt for the first time in your new project.

## 5. Create your first models

The final step is to create your first dbt model. We're going to create a basic `customers` model, with data from our customers and orders data. To do so, complete the following steps:

1. Hover over the 'models' directory in the file navigator to the left of the screen. Three dots will appear. Click on the dots and select new file.
2. A dialog box will appear at the top of the screen. We want to create a file called `customers.sql` in the `models` directory. You should input `models/customers.sql` and click 'OK'.
3. There will now be a file in the `models/` directory called `customers.sql`. Click on it. The file will be blank. Paste into that file the SQL from the bottom of this file.
4. Once pasted, click 'Preview' in the top left to see the results of the query. Click 'Save' in the top right corner to save the file.
5. Finally, we want to build this model as an object in our database. Once again, enter `dbt run` at the bottom of the page and click enter. You should now see your new `customers` model build, in addition to the two example models that came with the project.

You've now written your first dbt model and have completed the pre-course requirements. I'm looking forward to teaching all of you in the upcoming course!

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

