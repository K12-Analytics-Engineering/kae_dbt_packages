{% macro get_naive_school_year_from_date(date_field) %}
    if(
        extract(month from {{ date_field }}) >= 8,
        extract(year from {{ date_field }}) + 1,
        extract(year from {{ date_field }})
    )
{% endmacro %}
