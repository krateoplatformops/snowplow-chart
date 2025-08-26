def update_string_schema_defaults($input):
  $input as $root
  | ($root.getNotOrderedSchema | tostring | gsub("\\s{2,}"; " ")) as $schema
  | reduce (
      $root.getCompositionSpec
      | paths(scalars)
    ) as $p
    (
      $schema;
      . as $current
      | ($root.getCompositionSpec | getpath($p)) as $newValue
      | ($newValue | tojson) as $replacement
      | ($p | last) as $lastKey
      | ($p | (length-2) | if .>=0 then $p[.] else null end) as $parentKey
      | if ($parentKey != null) then
          # Require: "<parentKey>": { ... "<lastKey>": { ... "default": <old> ... "title":"<lastKey>" ... } }
          $current
          | gsub(
              "(?s)"
              + "(?<prefix>"
                + "\""+$parentKey+"\"\\s*:\\s*\\{"       # <-- parent object start
                + ".*?\""+$lastKey+"\"\\s*:\\s*\\{"      # <-- leaf object start
                + ".*?\"default\"\\s*:\\s*"              #     default value
              + ")"
              + "(\"[^\"]*\"|-?[0-9]+(?:\\.[0-9]+)?|true|false|null)"
              + "(?<suffix>.*?\"title\"\\s*:\\s*\""+$lastKey+"\".*?\\})";
              "\(.prefix)\($replacement)\(.suffix)"
            )
        else
          # Top-level leaf: "<lastKey>": { ... "default": <old> ... "title":"<lastKey>" ... }
          $current
          | gsub(
              "(?s)"
              + "(?<prefix>"
                + "\""+$lastKey+"\"\\s*:\\s*\\{"         # <-- leaf object start
                + ".*?\"default\"\\s*:\\s*"              #     default value
              + ")"
              + "(\"[^\"]*\"|-?[0-9]+(?:\\.[0-9]+)?|true|false|null)"
              + "(?<suffix>.*?\"title\"\\s*:\\s*\""+$lastKey+"\".*?\\})";
              "\(.prefix)\($replacement)\(.suffix)"
            )
        end
    )
;

def update_schema_defaults($input):
  $input as $root
  | ($root.getOrderedSchema) as $schema
  | reduce (
      $root.getCompositionSpec
      | paths(scalars)
    ) as $p
    (
      $schema;
      ($root.getCompositionSpec | getpath($p)) as $newValue
      | (
          ([$p[] | ["properties", .]] | add)
          + ["default"]
        ) as $schemaPath
      | setpath($schemaPath; $newValue)
    )
  | del(.properties.composition)
;