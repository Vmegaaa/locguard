/// Extract brace placeholders as an ASCII lexical sorted multiset of their exact names.
///
/// Supported forms are `{name}` and `{0}`. Named identifiers contain only ASCII
/// letters, digits, and underscores and start with a letter or underscore.
/// Positional identifiers contain only digits. `{{` and `}}` are literal braces.
/// Duplicate placeholders are preserved so missing repetitions remain visible.
/// ICU messages, format specifiers, and malformed braces return an error.
/// Error positions count Unicode characters, starting at one.

///|
pub fn extract(input : String) -> Result[Array[String], String] {
  let chars = input.to_array()
  let names : Array[String] = []
  let mut i = 0
  while i < chars.length() {
    if chars[i] == '{' {
      if i + 1 < chars.length() && chars[i + 1] == '{' {
        i += 2
        continue
      }
      let start = i
      i += 1
      let name_buf = StringBuilder()
      let mut first = true
      let mut positional = false
      let mut valid = true
      while i < chars.length() && chars[i] != '}' {
        let c = chars[i]
        if c == ',' {
          return Err("unsupported ICU placeholder at character \{start + 1}")
        }
        if c == ':' || c == '!' {
          return Err("unsupported format specifier at character \{start + 1}")
        }
        if c == '{' {
          return Err(
            "invalid placeholder name: nested opening brace at character \{i + 1}",
          )
        }
        let digit = '0' <= c && c <= '9'
        let letter = ('a' <= c && c <= 'z') || ('A' <= c && c <= 'Z')
        if first {
          positional = digit
          valid = letter || digit || c == '_'
          first = false
        } else if positional {
          valid = valid && digit
        } else {
          valid = valid && (letter || digit || c == '_')
        }
        name_buf.write_char(c)
        i += 1
      }
      if i == chars.length() {
        return Err("unclosed placeholder at character \{start + 1}")
      }
      if first {
        return Err(
          "invalid placeholder name: empty name at character \{start + 1}",
        )
      }
      if !valid {
        return Err("invalid placeholder name at character \{start + 1}")
      }
      names.push(name_buf.to_string())
      i += 1
    } else if chars[i] == '}' {
      if i + 1 < chars.length() && chars[i + 1] == '}' {
        i += 2
      } else {
        return Err("unmatched closing brace at character \{i + 1}")
      }
    } else {
      i += 1
    }
  }
  names.sort_by((a, b) => a.lexical_compare(b))
  Ok(names)
}
