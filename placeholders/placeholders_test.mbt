///|
test "plain and multilingual text contain no placeholders" {
  assert_eq(@placeholders.extract(""), Ok([]))
  assert_eq(@placeholders.extract("你好 🌍 Welcome"), Ok([]))
}

///|
test "named and positional placeholders form a sorted multiset" {
  assert_eq(
    @placeholders.extract("{player} scored {0}; {player}, {_item2}, {12}"),
    Ok(["0", "12", "_item2", "player", "player"]),
  )
  assert_eq(
    @placeholders.extract("{a}{b}{a}"),
    @placeholders.extract("{b}{a}{a}"),
  )
  assert_true(
    @placeholders.extract("{a}{b}{a}") != @placeholders.extract("{a}{b}"),
  )
}

///|
test "escaped braces do not introduce placeholders" {
  assert_eq(@placeholders.extract("{{name}} and {{0}}"), Ok([]))
  assert_eq(@placeholders.extract("{{{name}}}"), Ok(["name"]))
  assert_eq(@placeholders.extract("{{ and }}"), Ok([]))
  assert_eq(@placeholders.extract("{{{{}}}}"), Ok([]))
}

///|
test "exact case and positional spelling remain distinct" {
  assert_eq(@placeholders.extract("{A}{a}{0}{00}"), Ok(["0", "00", "A", "a"]))
  assert_eq(@placeholders.extract("{_}{a_1}{123}"), Ok(["123", "_", "a_1"]))
}

///|
test "unclosed placeholders and stray closing braces are errors" {
  assert_eq(
    @placeholders.extract("hello {name"),
    Err("unclosed placeholder at character 7"),
  )
  assert_eq(
    @placeholders.extract("{"),
    Err("unclosed placeholder at character 1"),
  )
  assert_eq(
    @placeholders.extract("hello }"),
    Err("unmatched closing brace at character 7"),
  )
  assert_eq(
    @placeholders.extract("{name}}"),
    Err("unmatched closing brace at character 7"),
  )
  assert_eq(
    @placeholders.extract("🌍}"),
    Err("unmatched closing brace at character 2"),
  )
}

///|
test "invalid names are rejected instead of silently ignored" {
  assert_eq(
    @placeholders.extract("{}"),
    Err("invalid placeholder name: empty name at character 1"),
  )
  for
    input in [
      "{ name}", "{name }", "{first-name}", "{玩家}", "{0name}", "{9_}",
    ] {
    assert_eq(
      @placeholders.extract(input),
      Err("invalid placeholder name at character 1"),
    )
  }
  assert_eq(
    @placeholders.extract("{a{b}}"),
    Err("invalid placeholder name: nested opening brace at character 3"),
  )
}

///|
test "ICU and format strings fail explicitly" {
  assert_eq(
    @placeholders.extract("{count, plural, one {item} other {items}}"),
    Err("unsupported ICU placeholder at character 1"),
  )
  assert_eq(
    @placeholders.extract("{price:.2f}"),
    Err("unsupported format specifier at character 1"),
  )
  assert_eq(
    @placeholders.extract("{name!r}"),
    Err("unsupported format specifier at character 1"),
  )
}
