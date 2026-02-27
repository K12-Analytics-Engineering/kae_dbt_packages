
{% macro get_unweighted_gpa_point(letter_grade) %}
    case {{ letter_grade }}
        when 'A+'   then 4
        when 'A'    then 4
        when 'A-'   then 4
        when 'B+'   then 3
        when 'B'    then 3
        when 'B-'   then 3
        when 'C+'   then 2
        when 'C'    then 2
        when 'C-'   then 2
        when 'D+'   then 1
        when 'D'    then 1
        when 'D-'   then 1
        when 'F'    then 0
    end
{% endmacro %}
