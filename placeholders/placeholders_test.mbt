///|
test "plain and multilingual text contain no placeholders" {
  assert_eq(extract(""), Ok([]))
  assert_eq(extract("你好 🌍 Welcome"), Ok([]))
}

///|
test "named and positional placeholders form a sorted multiset" {
  assert_eq(
    extract("{player} scored {0}; {player}, {_item2}, {12}"),
    Ok(["0", "12", "_item2", "player", "player"]),
  )
  assert_eq(extract("{a}{b}{a}"), extract("{b}{a}{a}"))
  assert_true(extract("{a}{b}{a}") != extract("{a}{b}"))
}

///|
test "escaped braces do not introduce placeholders" {
  assert_eq(extract("{{name}} and {{0}}"), Ok([]))
  assert_eq(extract("{{{name}}}"), Ok(["name"]))
  assert_eq(extract("{{ and }}"), Ok([]))
  assert_eq(extract("{{{{}}}}"), Ok([]))
}

///|
test "exact case and positional spelling remain distinct" {
  assert_eq(extract("{A}{a}{0}{00}"), Ok(["0", "00", "A", "a"]))
  assert_eq(extract("{_}{a_1}{123}"), Ok(["123", "_", "a_1"]))
}

///|
test "unclosed placeholders and stray closing braces are errors" {
  assert_eq(extract("hello {name"), Err("unclosed placeholder at character 7"))
  assert_eq(extract("{"), Err("unclosed placeholder at character 1"))
  assert_eq(extract("hello }"), Err("unmatched closing brace at character 7"))
  assert_eq(extract("{name}}"), Err("unmatched closing brace at character 7"))
  assert_eq(extract("🌍}"), Err("unmatched closing brace at character 2"))
}

///|
test "invalid names are rejected instead of silently ignored" {
  assert_eq(extract("{}"), Err("invalid placeholder name: empty name at character 1"))
  for input in ["{ name}", "{name }", "{first-name}", "{玩家}", "{0name}", "{9_}"] {
    assert_eq(extract(input), Err("invalid placeholder name at character 1"))
  }
  assert_eq(
    extract("{a{b}}"),
    Err("invalid placeholder name: nested opening brace at character 3"),
  )
}

///|
test "ICU and format strings fail explicitly" {
  assert_eq(
    extract("{count, plural, one {item} other {items}}"),
    Err("unsupported ICU placeholder at character 1"),
  )
  assert_eq(extract("{price:.2f}"), Err("unsupported format specifier at character 1"))
  assert_eq(extract("{name!r}"), Err("unsupported format specifier at character 1"))
}
