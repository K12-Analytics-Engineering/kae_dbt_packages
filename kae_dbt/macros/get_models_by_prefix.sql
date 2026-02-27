{% macro get_models_by_prefix(prefix) %}

{% if execute %}

    {% set models = [] %}

    {% for model in graph.nodes.values() | selectattr("resource_type", "equalto", "model") %}

        {% if model.name.startswith(prefix) %}

            {{ models.append(model) }}

        {% endif %}

    {% endfor %}

    {{ return(models) }}

{% endif %}

{% endmacro %}
