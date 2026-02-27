{% macro format_phone_number(phone_number) %}
    concat(
        left({{ phone_number }}, 3),
        '-',
        substr({{ phone_number }}, 4, 3),
        '-',
        right({{ phone_number }}, 4)
    )
{% endmacro %}