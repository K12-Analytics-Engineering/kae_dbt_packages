{% macro clean_phone_number(phone_number) %}
    regexp_substr(
        regexp_replace(
            regexp_substr(
                ltrim(
                    {{ phone_number }}, '+'
                ),
                r'^([^a-zA-z/]+)'
            ),
            '[^0-9]', ''
        ),
        r'^[1]?([^a-zA-z/]{10})'
    )
{% endmacro %}
