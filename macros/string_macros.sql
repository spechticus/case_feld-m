-- macros/replace_local_characters.sql
{% macro replace_local_characters(input_string) %}

{# This is a dictionary of to be replaced characters that we will later use in a nested 
call to the REPLACE() function.#}

  {% set replacements = {
        'ä': 'ae',
        'ö': 'oe',
        'ü': 'ue',
        'ß': 'ss',
        'à': 'a',
        'â': 'a',
        'ç': 'c',
        'é': 'e',
        'è': 'e',
        'ê': 'e',
        'ë': 'e',
        'î': 'i',
        'ï': 'i',
        'ô': 'o',
        'ù': 'u',
        'û': 'u',
        'ñ': 'n',
        'á': 'a',
        'í': 'i',
        'ó': 'o',
        'ú': 'u',
        'õ': 'o',
        'à': 'a',
        'ç': 'c',
        'å': 'a',
        'æ': 'ae',
        'ø': 'oe',
        'ë': 'e',
        'ï': 'i',
        'ł': 'l',
        'ń': 'n',
        'ś': 's',
        'ź': 'z',
        'ż': 'z',
        'č': 'c',
        'ě': 'e',
        'ň': 'n',
        'ř': 'r',
        'š': 's',
        'ť': 't',
        'ů': 'u',
        'ý': 'y',
        'ž': 'z',
        'ő': 'o',
        'ű': 'u'
  } %}



  {% set nested_replace = input_string %}

    {# It is R_E_A_L_L_Y annoying to nest function calls inside a Jinja loop because variables
    set inside a loop cannot be carried over to outside the loop. To fix this,
    you can use namespaces.#}

  {% set ns = namespace(replace_expr=input_string) %}
  
  {% for key, value in replacements.items() %}
    {% set ns.replace_expr = "replace(" ~ ns.replace_expr ~ ", '" ~ key ~ "', '" ~ value ~ "')" %}
  {% endfor %}
  
  {{ ns.replace_expr }}
{% endmacro %}