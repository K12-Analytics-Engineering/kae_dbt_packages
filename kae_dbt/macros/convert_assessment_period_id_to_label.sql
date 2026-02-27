{% macro convert_assessment_period_id_to_label(assessment_period_id) %}
    case {{ assessment_period_id }}
        when 1 then 'fall'
        when 2 then 'winter'
        when 3 then 'spring'
        when 4 then 'summer'
    end
{% endmacro %}
