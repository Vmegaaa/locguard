///|
/// A parsed CSV record and its one-based starting physical line.
pub(all) struct Row {
  fields : Array[String]
  line : Int
} derive(Eq, Debug)

///|
#deprecated
pub extend Row with Eq::{equal, not_equal}

///|
#deprecated
pub extend Row with Debug::{to_repr}

///|
/// A syntax error. Columns count Unicode code points, starting at one.
pub(all) struct ParseError {
  line : Int
  column : Int
  message : String
} derive(Eq, Debug)

///|
#deprecated
pub extend ParseError with Eq::{equal, not_equal}

///|
#deprecated
pub extend ParseError with Debug::{to_repr}

///|
priv enum FieldState {
  Start
  Unquoted
  Quoted
  Closed
} derive(Eq)

///|
/// Parse comma-separated records using RFC 4180 quoting rules.
///
/// Both LF and CRLF record endings are accepted. Quoted content, including
/// embedded line endings, is preserved. A UTF-8 BOM decoded to U+FEFF is
/// ignored only at the start of the input. Empty input has no records;
/// actual blank records contain one empty field. An ending record separator
/// does not create a second, phantom record.
///
/// A bare CR outside a quoted field, a quote inside an unquoted field, or
/// text following a closing quote is rejected. Unclosed quotes report the
/// opening quote's location. Field counts are left to the schema validator.
pub fn parse(input : String) -> Result[Array[Row], ParseError] {
  let chars : Array[Char] = input.iter().collect()
  let rows : Array[Row] = []
  let mut fields : Array[String] = []
  let mut field = StringBuilder()
  let mut state = Start
  let mut offset = 0
  let mut line = 1
  let mut column = 1
  let mut row_line = 1
  let mut quote_line = 1
  let mut quote_column = 1
  let mut record_started = false
  if chars.length() > 0 && chars[0] == '\uFEFF' {
    offset = 1
  }
  while offset < chars.length() {
    let ch = chars[offset]
    if state == Quoted {
      if ch == '"' {
        if offset + 1 < chars.length() && chars[offset + 1] == '"' {
          field.write_char('"')
          offset += 2
          column += 2
        } else {
          state = Closed
          offset += 1
          column += 1
        }
      } else if ch == '\r' {
        field.write_char(ch)
        offset += 1
        if offset < chars.length() && chars[offset] == '\n' {
          field.write_char('\n')
          offset += 1
        }
        line += 1
        column = 1
      } else if ch == '\n' {
        field.write_char(ch)
        offset += 1
        line += 1
        column = 1
      } else {
        field.write_char(ch)
        offset += 1
        column += 1
      }
    } else if ch == ',' {
      fields.push(field.to_string())
      field = StringBuilder()
      state = Start
      record_started = true
      offset += 1
      column += 1
    } else if ch == '\r' || ch == '\n' {
      if ch == '\r' {
        if offset + 1 >= chars.length() || chars[offset + 1] != '\n' {
          return Err({
            line,
            column,
            message: "Bare carriage return outside a quoted field",
          })
        }
        offset += 1
      }
      fields.push(field.to_string())
      rows.push({ fields, line: row_line, })
      fields = []
      field = StringBuilder()
      state = Start
      record_started = false
      offset += 1
      line += 1
      column = 1
      row_line = line
    } else if state == Closed {
      return Err({
        line,
        column,
        message: "Expected a comma or record ending after a closing quote",
      })
    } else if ch == '"' {
      if state == Unquoted {
        return Err({ line, column, message: "Quote inside an unquoted field", })
      }
      state = Quoted
      record_started = true
      quote_line = line
      quote_column = column
      offset += 1
      column += 1
    } else {
      field.write_char(ch)
      state = Unquoted
      record_started = true
      offset += 1
      column += 1
    }
  }
  if state == Quoted {
    return Err({
      line: quote_line,
      column: quote_column,
      message: "Unclosed quoted field",
    })
  }
  if record_started {
    fields.push(field.to_string())
    rows.push({ fields, line: row_line, })
  }
  Ok(rows)
}
