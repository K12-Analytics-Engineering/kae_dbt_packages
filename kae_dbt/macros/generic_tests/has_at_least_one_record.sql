{% test has_at_least_one_record(model) %}
    select 1
    from {{ model }}
    having count(*) = 0
{% endtest %}
