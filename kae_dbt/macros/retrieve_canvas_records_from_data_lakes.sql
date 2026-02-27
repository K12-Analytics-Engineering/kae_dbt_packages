{% macro retrieve_canvas_records_from_data_lake(table_name, unique_key_name='id') %}

with
all_upserts as (
    select
        json_value(data, '$.key.{{ unique_key_name }}')    as {{ unique_key_name }},
        parse_timestamp(
            '%Y-%m-%dT%H:%M:%E3SZ',
            json_value(data, '$.meta.ts')
        )                                                   as date_metadata,
        date_extracted,
        json_query(data, '$.value')                         as json_data,
    from
        {{ source('staging', table_name) }}
    where
        json_value(data, '$.meta.action') = 'U'
        or json_value(data, '$.meta.action') is null
),

upserts as (
    select
        *
    from
        all_upserts
    qualify
        row_number() over (
            partition by {{ unique_key_name }}
            order by date_metadata desc
        ) = 1
),

all_deletes as (
    select
        json_value(data, '$.key.{{ unique_key_name }}')     as {{ unique_key_name }},
        parse_timestamp(
            '%Y-%m-%dT%H:%M:%E3SZ',
            json_value(data, '$.meta.ts')
        )                                                   as date_metadata,
    from
        {{ source('staging', table_name) }}
    where
        json_value(data, '$.meta.action') = 'D'
),

deletes as (
    select
        *
    from
        all_deletes
    qualify
        row_number() over (
            partition by {{ unique_key_name }}
            order by date_metadata desc
        ) = 1
),

records as (
    select
        upserts.{{ unique_key_name }},
        upserts.date_metadata,
        upserts.date_extracted,
        upserts.json_data,
    from
        upserts
        left join deletes
            on upserts.{{ unique_key_name }} = deletes.{{ unique_key_name }}
    where
        deletes.{{ unique_key_name }} is null
)

{% endmacro %}