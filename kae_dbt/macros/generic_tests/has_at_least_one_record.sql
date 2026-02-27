{% test has_at_least_one_record(model) %}
    select 1
    where (select count(*) from {{ model }}) = 0
{% endtest %}
