{% macro convert_grade_level_to_id(grade_level) %}
    case lower({{ grade_level }})
        when 'infant/toddler'               then -4
        when 'p2'                           then -3
        when 'p3'                           then -2
        when 'pk3'                          then -2
        when '-2'                           then -2
        when 'p'                            then -1
        when 'pk'                           then -1
        when 'pk4'                          then -1
        when 'preschool/prekindergarten'    then -1
        when '-1'                           then -1
        when '0'                            then 0
        when 'k'                            then 0
        when 'kk'                           then 0
        when 'k1'                           then 0
        when 'kindergarten'                 then 0
        when '1'                            then 1
        when '01'                           then 1
        when 'first grade'                  then 1
        when '1st grade'                    then 1
        when '1st'                          then 1
        when '2'                            then 2
        when '02'                           then 2
        when 'second grade'                 then 2
        when '2nd grade'                    then 2
        when '2nd'                          then 2
        when '3'                            then 3
        when '03'                           then 3
        when 'third grade'                  then 3
        when '3rd grade'                    then 3
        when '3rd'                          then 3
        when '4'                            then 4
        when '04'                           then 4
        when 'fourth grade'                 then 4
        when '4th grade'                    then 4
        when '4th'                          then 4
        when '5'                            then 5
        when '05'                           then 5
        when 'fifth grade'                  then 5
        when '5th grade'                    then 5
        when '5th'                          then 5
        when '6'                            then 6
        when '06'                           then 6
        when 'sixth grade'                  then 6
        when '6th grade'                    then 6
        when '6th'                          then 6
        when '7'                            then 7
        when '07'                           then 7
        when 'seventh grade'                then 7
        when '7th grade'                    then 7
        when '7th'                          then 7
        when '8'                            then 8
        when '08'                           then 8
        when 'eighth grade'                 then 8
        when '8th grade'                    then 8
        when '8th'                          then 8
        when '9'                            then 9
        when '09'                           then 9
        when 'ninth grade'                  then 9
        when '9th grade'                    then 9
        when '9th'                          then 9
        when '10'                           then 10
        when 'tenth grade'                  then 10
        when '10th grade'                   then 10
        when '10th'                         then 10
        when '11'                           then 11
        when 'eleventh grade'               then 11
        when '11th grade'                   then 11
        when '11th'                         then 11
        when '12'                           then 12
        when 'twelfth grade'                then 12
        when '12th grade'                   then 12
        when '12th'                         then 12
        when '13'                           then 13
        when 'adult'                        then 20
                                            else 999999999
    end
{% endmacro %}
