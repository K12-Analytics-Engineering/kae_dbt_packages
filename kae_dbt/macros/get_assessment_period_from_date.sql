{% macro get_assessment_period_from_date(dt, fmt='%Y-%m-%d') %}
    case
        when coalesce(extract(month from safe.parse_date('{{ fmt }}', {{ dt }})), 0) between 1 and 2 then 'Winter'
        when coalesce(extract(month from safe.parse_date('{{ fmt }}', {{ dt }})), 0) between 3 and 7 then 'Spring'
        when coalesce(extract(month from safe.parse_date('{{ fmt }}', {{ dt }})), 0) between 8 and 10 then 'Fall'
        when coalesce(extract(month from safe.parse_date('{{ fmt }}', {{ dt }})), 0) between 11 and 12 then 'Winter'
        else cast(null as string)
    end
{% endmacro %}
