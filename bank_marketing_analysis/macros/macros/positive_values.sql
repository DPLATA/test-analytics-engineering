{% macro test_positive_values(model, column_name) %}

select
    {{ column_name }} as positive_field
from {{ model }}
where {{ column_name }} <= 0
    or {{ column_name }} is null

{% endmacro %}