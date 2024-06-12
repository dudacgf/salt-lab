{%- macro dict_to_list(dictlist) %}
  {%- set ls = [] %}
  {%- for k, v in dictlist.items() %}
    {%- do ls.append({k: v}) %}
  {%- endfor %}
  {{ ls }}
{%- endmacro %}
