{% macro generate_database_name(custom_database_name=none, node=none) -%}

    {%- if custom_database_name is none -%}

        {{ target.database }}

    {%- else -%}

        {{ custom_database_name | trim }}

    {%- endif -%}

{%- endmacro %}
