{% macro is_actively_enrolled(entry_date, exit_date) %}
    if(
        (
            {{ exit_date }} is null
            -- null exit_date can't be associated with long-past entry_date
            and {{ dateadd('year', -1, 'current_date') }} < {{ entry_date }}
        )
        or
        (
            current_date >= {{ entry_date }}
            and current_date < {{ exit_date }}
        ),
        1, 0
    )
{% endmacro %}
