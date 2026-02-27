{% macro get_week_of_school_year(raw_date, week_of_year, start_week) %}
    if(
        {{ week_of_year }} >= {{ start_week }},
        ({{ week_of_year }} - {{ start_week }}) + 1,
        (({{ week_of_year }} + extract(week from date_add({{ raw_date }}, interval -(extract(day from {{ raw_date }})) day))) - {{ start_week }}) + 1
    )
{% endmacro %}