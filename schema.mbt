///|
fn check_header(
  row : @csv.Row,
  source_override : String?,
  issues : Array[Issue],
) -> Int {
  let header = row.fields
  if header.length() < 3 {
    add_issue(
      issues,
      "header",
      row.line,
      "",
      "",
      "Expected key and at least two locale columns",
    )
    return -1
  }
  if header[0] != "key" {
    add_issue(
      issues,
      "header",
      row.line,
      header[0],
      "",
      "First column must be named key",
    )
  }
  let seen : Map[String, Int] = Map([])
  for column, name in header {
    if blank(name) {
      add_issue(
        issues,
        "header",
        row.line,
        "\{column + 1}",
        "",
        "Header names must not be empty",
      )
    }
    match seen.get(name) {
      Some(_) =>
        add_issue(issues, "header", row.line, name, "", "Duplicate header name")
      None => seen.set(name, column)
    }
  }
  let source = match source_override {
    None => 1
    Some(name) =>
      match seen.get(name) {
        Some(i) if i > 0 => i
        _ => {
          add_issue(
            issues,
            "source",
            row.line,
            name,
            "",
            "Source locale must name an existing locale column",
          )
          -1
        }
      }
  }
  if issues.is_empty() {
    source
  } else {
    -1
  }
}

///|
/// Validate using the first locale column as source.
pub fn validate(input : String) -> Report {
  validate_document(input, None)
}

///|
/// Validate using an explicitly named source locale.
pub fn validate_with_source(input : String, source_locale : String) -> Report {
  validate_document(input, Some(source_locale))
}

///|
fn validate_document(input : String, source_override : String?) -> Report {
  let issues : Array[Issue] = []
  let rows = match @csv.parse(input) {
    Ok(rows) => rows
    Err(error) => {
      add_issue(issues, "csv", error.line, "\{error.column}", "", error.message)
      return { rows_checked: 0, source_locale: "", issues, }
    }
  }
  if rows.is_empty() {
    add_issue(issues, "header", 1, "", "", "CSV is empty; expected a header")
    return { rows_checked: 0, source_locale: "", issues, }
  }
  let source = check_header(rows[0], source_override, issues)
  if source < 0 {
    return { rows_checked: 0, source_locale: "", issues, }
  }
  let header = rows[0].fields
  let source_locale = header[source]
  check_translations(rows, header, source, issues)
  { rows_checked: rows.length() - 1, source_locale, issues, }
}
