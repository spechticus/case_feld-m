-- macros/replace_local_characters.sql
{% macro replace_local_characters(input_string) %}
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

  {% set result_string = input_string %}

  {% for key, value in replacements.items() %}
    {% set result_string = result_string | replace(key, value) %}
  {% endfor %}

  {{ return(result_string) }}
{% endmacro %}
