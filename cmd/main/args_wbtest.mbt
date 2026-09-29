///|
test "options can precede or follow path and support a different source locale" {
  assert_eq(
    parse_args(["--json", "--source", "zh_CN", "strings.csv"]),
    Ok({ path: "strings.csv", source: Some("zh_CN"), json: true, }),
  )
  assert_eq(
    parse_args(["strings.csv", "--json"]),
    Ok({ path: "strings.csv", source: None, json: true, }),
  )
  assert_eq(
    parse_args(["--", "-strings.csv"]),
    Ok({ path: "-strings.csv", source: None, json: false, }),
  )
}

///|
test "usage mistakes cannot silently select a different file" {
  let invalid_args : Array[FixedArray[String]] = [
    [],
    ["--source"],
    ["--source", "--json", "strings.csv"],
    ["--unknown"],
    ["a.csv", "b.csv"],
    ["--source", "en", "--source", "zh", "a.csv"],
  ]
  for args in invalid_args {
    match parse_args(args) {
      Err(_) => ()
      Ok(_) => fail("Expected a usage error")
    }
  }
}
