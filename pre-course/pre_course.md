# Pre-Course Work

The goal of this pre-work is to get each student set up in Snowflake and dbt Cloud, as well as create the beginnings of the dbt project that we will develop over the course.

If at any point you have any questions or something doesn't appear to be working as you'd expect, please reply to the introduction email and I'll make sure we get it all sorted out.

## 1. Set up Snowflake account

You will have received your Snowflake user name in the introduction message. Once you log into Snowflake, you should see the Snowflake editor (**if prompted, select Classic UI instead of Snowsight**). Run the following query to verify you have the correct permissions:

```sql
use role transformer;
use warehouse compute_wh;

select
    *
from raw.ecomm.orders
limit 100;
```

If you see orders data, you're good to go!

## 2. Set up dbt Cloud account

You will also have received an invite for the dbt Cloud project. Click on the link in the email and fill out the onboarding form with your personal information.

## 3. Configure dbt Cloud

For the purposes of the course, you'll be creating your own dbt Cloud project. To do so, follow the following steps:

1. Click on the cogwheel menu in the top right corner and select 'Account Settings'.
2. Click on the 'Projects' tab on the left and click 'New Project' on the right.
3. Project name: Name the project 'dbt training - (first initial) (last name)'. For Simo Tumelius, this would be 'dbt training - S Tumelius'.
4. Warehouse: Select Snowflake
5. Environment: Name the environment 'Snowflake'. Under Settings fill the following details:
    - Account: wpa36811
    - Database: analytics
    - Warehouse: compute_wh
    - Role: transformer
    - Session Keep Alive: No
    - Auth Method: Username & Password
    - Username: Your Snowflake username
    - Password: Your Snowflake password
    - Schema: dbt_(first initial)(last name), i.e. for Simo Tumelius it would be dbt_stumelius
    - Target Name: dev
    - Threads: 2
8. Click 'Test connection'. If you the tests pass, click 'Next'. If the tests fail, return to the prior two steps and make sure all the details are entered correctly.
9. Repository: Select 'Managed'. This will create a git repository in the dbt Cloud for you. Name the repository 'dbt_training_(firstinitial)(lastname)' and click 'Create'. For Simo Tumelius, this would be 'dbt_training_stumelius'. If the repository name is already taken, add a suffix to it (e.g., 'dbt_training_stumelius_1')
10. Your project is ready!

## 4. Initialize your dbt project

After configuring the previous steps, you should be brought back to the main page. You should be prompted to 'Start developing in the IDE'. Click that button. If you do not see the button, click on Develop in the top left menu. Once you're brought to the IDE, it will take a few seconds to set everything up.

There will be a big green button in the top left corner that says 'Initialize your project'. Click that button. dbt Cloud will now create a template dbt Project for you to start developing. Next, click 'Commit and push' in the top left corner, enter 'Initial commit' as the commit message and click 'Commit Changes'.

You're still on a read-only main branch (git lingo) so you still need to create a branch for your work. Click 'Create branch' in the top left corner, name it '(firstinitial)(lastname)' (e.g., 'stumelius') and click 'Submit'.

To test that everything is set up properly, we're going to try building some dbt models. There are two example models in the project by default.

Type in 'dbt run' in the bar at the bottom of your screen (if it isn't already there by default) and click enter. You should see two models, `my_first_dbt_model` and `my_second_dbt_model`, complete successfully.

Congratulations! You've just run dbt for the first time in your new project.

[](dbt_cloud_ide.png)

## 5. Create your first models

The final step is to create your first dbt model. We're going to create a basic `customers` model, with data from our customers and orders data. To do so, complete the following steps:

1. Delete the example models that came with the dbt project initialization. Hover over the `models/examples` directory in the file navigator to the left of the screen. Three dots will appear. Click on the dots and select 'Delete'.
2. Hover over the `models` directory in the file navigator, click on the three dots and select 'Create File'.
3. A dialog box will appear. We want to create a file called `customers.sql` in the `models` directory. You should input `customers.sql` and click 'OK'.
    * Make sure the `customers.sql` file is in the `models/` directory. If not, you can drag and drop it there.
4. Click on the newly created `models/customers.sql` file. The file will be blank. Paste into that file the SQL from the bottom of this file.
5. Once pasted, click 'Preview' in the editor. Click 'Save' in the top right corner to save the file.
6. Finally, we want to build this model as an object in our database. Once again, enter `dbt run` at the bottom of the page and click enter. You should now see your new `customers` model build.

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

