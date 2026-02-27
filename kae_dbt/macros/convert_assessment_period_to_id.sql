{% macro convert_assessment_period_to_id(assessment_period) %}
    case lower({{ assessment_period }})
        when 'fall'     then 1
        when 'winter'   then 2
        when 'spring'   then 3
        when 'summer'   then 4
    end
{% endmacro %}
