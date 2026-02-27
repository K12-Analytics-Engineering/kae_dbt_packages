{% macro calculate_age_as_of_date(dob, as_of_date) %}
    (
        date_diff({{ as_of_date }}, {{ dob }}, year) - 
        if(
            (
                extract(month from {{ dob }}) * 100 + extract(day from {{ dob }}) > 
                extract(month from {{ as_of_date }}) * 100 + extract(day from {{ as_of_date }})
            ),
            1, 0
        )
    )
{% endmacro %}