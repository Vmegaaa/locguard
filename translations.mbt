fn check_translations(
  rows : Array[@csv.Row],
  header : Array[String],
  source : Int,
  issues : Array[Issue],
) -> Unit {
  let seen_keys : Map[String, Int] = {}
  for index = 1; index < rows.length(); index = index + 1 {
    let row = rows[index]
    let fields = row.fields
    if fields.length() != header.length() {
      add_issue(issues, "row_width", row.line, "", "", "Expected \{header.length()} columns, found \{fields.length()}")
      continue
    }
    let key = fields[0]
    if blank(key) {
      add_issue(issues, "empty_key", row.line, "key", key, "Localization key is empty")
    } else {
      match seen_keys.get(key) {
        Some(first) => add_issue(issues, "duplicate_key", row.line, "key", key, "Key already appeared on line \{first}"),
        None => seen_keys.set(key, row.line),
      }
    }
    let source_placeholders = if blank(fields[source]) {
      add_issue(issues, "empty_source", row.line, header[source], key, "Source translation is empty")
      None
    } else {
      match @placeholders.extract(fields[source]) {
        Ok(names) => Some(names)
        Err(message) => {
          add_issue(issues, "placeholder_syntax", row.line, header[source], key, message)
          None
        }
      }
    }
    for column = 1; column < header.length(); column = column + 1 {
      if column == source { continue }
      if blank(fields[column]) {
        add_issue(issues, "missing_translation", row.line, header[column], key, "Translation is empty")
        continue
      }
      match @placeholders.extract(fields[column]) {
        Err(message) => add_issue(issues, "placeholder_syntax", row.line, header[column], key, message)
        Ok(actual) => match source_placeholders {
          Some(expected) if expected != actual => add_issue(
            issues, "placeholder_mismatch", row.line, header[column], key,
            "Expected placeholder multiset \{expected}, found \{actual}",
          )
          _ => ()
        },
      }
    }
  }
}
