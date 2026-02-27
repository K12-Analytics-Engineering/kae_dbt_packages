{% macro calculate_age(dob) %}
    (
        date_diff(current_date('America/Chicago'), {{ dob }}, year) - 
        if(
            (
                extract(month from {{ dob }}) * 100 + extract(day from {{ dob }}) > 
                extract(month from current_date('America/Chicago')) * 100 + extract(day from current_date('America/Chicago'))
            ),
            1, 0
        )
    )
{% endmacro %}