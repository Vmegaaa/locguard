test "clean translation and reordered repeated placeholders" {
  let report = validate("key,zh_CN,en_US\ngreet,你好{name}{0}{name},Hello {name}{name}{0}\n")
  assert_true(report.is_clean())
  assert_eq(report.rows_checked, 1)
  assert_eq(report.source_locale, "zh_CN")
}

test "missing duplicated and extra placeholders cannot hide in a set" {
  let report = validate("key,en_US,zh_CN\na,{n}{n},你好{n}\nb,{n},你好{n}{x}\nc,{Name},你好{name}\n")
  assert_eq(report.issues.length(), 3)
  for issue in report.issues {
    assert_eq(issue.code, "placeholder_mismatch")
  }
}

test "duplicate keys empty fields and malformed row widths" {
  let report = validate("key,en_US,zh_CN\na,Hello,你好\na,Again,又来\nb,Missing,\nc,too,few,columns\n,Empty key,空\n")
  assert_eq(report.rows_checked, 5)
  assert_eq(report.issues.map(fn(i) { i.code }), ["duplicate_key", "missing_translation", "row_width", "empty_key"])
  assert_eq(report.issues[0].line, 3)
}

test "bad headers and invalid explicit source are fatal before reading rows" {
  for input in ["", "key,en_US\na,Hello\n", "id,en_US,zh_CN\na,Hi,你好\n", "key,en_US,en_US\na,A,B\n", "key,,zh_CN\na,A,B\n"] {
    let report = validate(input)
    assert_false(report.is_clean())
    assert_eq(report.rows_checked, 0)
  }
  assert_eq(validate_with_source("key,en_US,zh_CN\na,A,B\n", "fr_FR").issues[0].code, "source")
  assert_eq(validate_with_source("key,en_US,zh_CN\na,A,B\n", "key").issues[0].code, "source")
}

test "explicit source locale changes comparison direction" {
  let report = validate_with_source("key,en_US,zh_CN\na,Hello {name},你好{name}\n", "zh_CN")
  assert_true(report.is_clean())
  assert_eq(report.source_locale, "zh_CN")
}

test "syntax errors and empty source avoid cascading parity errors" {
  let report = validate("key,en_US,zh_CN\na,{,你好{name}\nb,   ,你好\nc,Hello,坏{\n")
  assert_eq(report.issues.map(fn(i) { i.code }), ["placeholder_syntax", "empty_source", "placeholder_syntax"])
}

test "quoted multilingual cells and line numbers survive physical newlines" {
  let report = validate("\u{feff}key,en_US,zh_CN\r\na,\"Hello,\n{name}\",\"你好，\n{name}\"\r\na,Again,又来\r\n")
  assert_eq(report.rows_checked, 2)
  assert_eq(report.issues.length(), 1)
  assert_eq(report.issues[0].code, "duplicate_key")
  assert_eq(report.issues[0].line, 5)
}

test "JSON diagnostics are valid and deterministic with unusual keys" {
  let report = validate("key,en_US,zh_CN\n\"quote\"\"key\",Hello,\n")
  let json = report.json()
  assert_true(@json.valid(json))
  assert_eq(json, report.json())
  assert_true(json.contains("missing_translation"))
}

test "Unicode whitespace does not disguise empty translations keys or locales" {
  let translations = validate("key,en_US,zh_CN\na,Hello,\u{3000}\nb,\u{a0},你好\n\u{2003},Hi,你好\n")
  assert_eq(translations.issues.map(fn(i) { i.code }), ["missing_translation", "empty_source", "empty_key"])
  assert_eq(validate("key,en_US,\u{3000}\na,Hi,你好\n").issues[0].code, "header")
}
