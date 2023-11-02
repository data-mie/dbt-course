{% set max_date = '2022-03-14' %}
{% if execute %}
    {% set results = run_query('select current_date()') %}
    {% set max_date = results.columns[0].values()[0] %}
{% endif %}

{{ log("Calendar max date: " ~ max_date) }}

{{ dbt_date.get_date_dimension('2020-01-01', max_date) }}