{% test has_at_least_one_record(model) %}
    select row_count
    from (
        select count(*) as row_count
        from {{ model }}
    )
    where row_count = 0
{% endtest %}