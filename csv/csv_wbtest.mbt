///|
test "empty input and BOM-only input have no records" {
  assert_eq(parse(""), Ok([]))
  assert_eq(parse("\uFEFF"), Ok([]))
}

///|
test "BOM is ignored only at file start" {
  assert_eq(
    parse("\uFEFFkey,en,zh\r\nhello,Hello,你好"),
    Ok([
      { fields: ["key", "en", "zh"], line: 1, },
      { fields: ["hello", "Hello", "你好"], line: 2, },
    ]),
  )
  assert_eq(parse("a,\uFEFFb"), Ok([{ fields: ["a", "\uFEFFb"], line: 1, }]))
}

///|
test "Unicode and supplementary characters are preserved" {
  assert_eq(
    parse("問候,你好,👩‍💻,𠮷,مرحبا"),
    Ok([
      {
        fields: ["問候", "你好", "👩‍💻", "𠮷", "مرحبا"],
        line: 1,
      },
    ]),
  )
}

///|
test "LF CRLF and optional final separator give identical records" {
  let expected : Result[Array[Row], ParseError] = Ok([
    { fields: ["key", "en"], line: 1, },
    { fields: ["welcome", "Welcome"], line: 2, },
  ])
  assert_eq(parse("key,en\nwelcome,Welcome"), expected)
  assert_eq(parse("key,en\nwelcome,Welcome\n"), expected)
  assert_eq(parse("key,en\r\nwelcome,Welcome"), expected)
  assert_eq(parse("key,en\r\nwelcome,Welcome\r\n"), expected)
}

///|
test "empty cells at every position including EOF" {
  assert_eq(
    parse(",middle,\n,,\n"),
    Ok([
      { fields: ["", "middle", ""], line: 1, },
      { fields: ["", "", ""], line: 2, },
    ]),
  )
  assert_eq(parse(","), Ok([{ fields: ["", ""], line: 1, }]))
  assert_eq(parse("value,"), Ok([{ fields: ["value", ""], line: 1, }]))
}

///|
test "actual empty records are retained without a phantom final record" {
  assert_eq(parse("\n"), Ok([{ fields: [""], line: 1, }]))
  assert_eq(
    parse("\r\n\r\n"),
    Ok([{ fields: [""], line: 1, }, { fields: [""], line: 2, }]),
  )
  assert_eq(
    parse("a\n\nb\n"),
    Ok([
      { fields: ["a"], line: 1, },
      { fields: [""], line: 2, },
      { fields: ["b"], line: 3, },
    ]),
  )
}

///|
test "quoted commas quotes and empty values" {
  assert_eq(
    parse("\"\",\"a,b\",\"She said \"\"你好\"\"\",\"\"\"\""),
    Ok([{ fields: ["", "a,b", "She said \"你好\"", "\""], line: 1, }]),
  )
}

///|
test "quoted line endings are preserved and record lines are physical" {
  assert_eq(
    parse("key,text\r\nfirst,\"a\r\nb\nc\"\r\nlast,done\r\n"),
    Ok([
      { fields: ["key", "text"], line: 1, },
      { fields: ["first", "a\r\nb\nc"], line: 2, },
      { fields: ["last", "done"], line: 5, },
    ]),
  )
}

///|
test "bare CR is allowed as quoted data" {
  assert_eq(
    parse("\"a\rb\",c\nnext,last"),
    Ok([
      { fields: ["a\rb", "c"], line: 1, },
      { fields: ["next", "last"], line: 3, },
    ]),
  )
}

///|
test "spaces remain significant rather than being trimmed" {
  assert_eq(
    parse("  key ,\" value \""),
    Ok([{ fields: ["  key ", " value "], line: 1, }]),
  )
}

///|
test "quote in an unquoted cell reports exact position" {
  assert_eq(
    parse("good,value\r\nbad,ab\"cd"),
    Err({ line: 2, column: 7, message: "Quote inside an unquoted field", }),
  )
}

///|
test "error columns count Unicode code points not UTF16 units" {
  assert_eq(
    parse("😀x\""),
    Err({ line: 1, column: 3, message: "Quote inside an unquoted field", }),
  )
  assert_eq(
    parse("\uFEFFa\""),
    Err({ line: 1, column: 2, message: "Quote inside an unquoted field", }),
  )
}

///|
test "text and spaces after a closing quote are invalid" {
  let error : ParseError = {
    line: 1,
    column: 4,
    message: "Expected a comma or record ending after a closing quote",
  }
  assert_eq(parse("\"a\"x"), Err(error))
  assert_eq(parse("\"a\" ,b"), Err(error))
}

///|
test "unclosed field reports opening quote even after multiline data" {
  assert_eq(
    parse("key,text\nhello,\"line one\r\nline two"),
    Err({ line: 2, column: 7, message: "Unclosed quoted field", }),
  )
  assert_eq(
    parse("\"\"\""),
    Err({ line: 1, column: 1, message: "Unclosed quoted field", }),
  )
}

///|
test "bare carriage return outside quotes is rejected" {
  assert_eq(
    parse("a\rb"),
    Err({
      line: 1,
      column: 2,
      message: "Bare carriage return outside a quoted field",
    }),
  )
  assert_eq(
    parse("a\r"),
    Err({
      line: 1,
      column: 2,
      message: "Bare carriage return outside a quoted field",
    }),
  )
}

///|
test "multiline errors retain line and codepoint column" {
  assert_eq(
    parse("\"a\r\nb\"oops"),
    Err({
      line: 2,
      column: 3,
      message: "Expected a comma or record ending after a closing quote",
    }),
  )
}

///|
test "field counts remain available for schema diagnostics" {
  assert_eq(
    parse("key,en,zh\nshort,Hello\nlong,Hello,你好,extra"),
    Ok([
      { fields: ["key", "en", "zh"], line: 1, },
      { fields: ["short", "Hello"], line: 2, },
      { fields: ["long", "Hello", "你好", "extra"], line: 3, },
    ]),
  )
}

///|
fn quote_for_test(value : String) -> String {
  let output = StringBuilder()
  output.write_char('"')
  for ch in value {
    if ch == '"' {
      output.write_char('"')
    }
    output.write_char(ch)
  }
  output.write_char('"')
  output.to_string()
}

///|
test "quoted pairs round trip across a punctuation and Unicode corpus" {
  let cells = [
    "", "plain", ",", "\"", "\"\"", "x,y", "x\ny", "x\r\ny", "😀你好", " x ",
  ]
  for left in cells {
    for right in cells {
      let serialized = quote_for_test(left) + "," + quote_for_test(right)
      assert_eq(parse(serialized), Ok([{ fields: [left, right], line: 1, }]))
      assert_eq(
        parse(serialized + "\r\n"),
        Ok([{ fields: [left, right], line: 1, }]),
      )
    }
  }
}
