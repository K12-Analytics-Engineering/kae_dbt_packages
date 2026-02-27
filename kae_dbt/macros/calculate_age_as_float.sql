{% macro calculate_age_as_float(dob) %}
round(
    (
        -- units = age in years
        {{ calculate_age(dob) }} +
        -- decimal = days since last bday / days between bdays
        safe_divide(
            -- days since last bday
            date_diff(
                current_date('America/Chicago'),
                date_add(
                    {{ dob }}, interval {{ calculate_age(dob) }} year
                ),
                day
            ),
            -- days between bdays
            if(
                (
                    extract(month from {{ dob }}) * 100 + extract(day from {{ dob }}) > 
                    extract(month from current_date('America/Chicago')) * 100 + extract(day from current_date('America/Chicago'))
                ),
                date_diff(
                    date_add(
                        {{ dob }}, interval {{ calculate_age(dob) }} year
                    ),
                    date_add(
                        {{ dob }}, interval {{ calculate_age(dob) }} - 1 year
                    ),
                    day
                ),
                date_diff(
                    date_add(
                        {{ dob }}, interval {{ calculate_age(dob) }} + 1 year
                    ),
                    date_add(
                        {{ dob }}, interval {{ calculate_age(dob) }} year
                    ),
                    day
                )
            )
        )
    ), 3
)
{% endmacro %}