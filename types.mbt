///|
/// A stable diagnostic suitable for both a translator and a CI job.
pub(all) struct Issue {
  code : String
  line : Int
  column : String
  key : String
  message : String
} derive(Eq, Debug, ToJson)

///|
/// The number of data records excludes the header, including malformed-width rows.
pub(all) struct Report {
  rows_checked : Int
  source_locale : String
  issues : Array[Issue]
} derive(Eq, Debug, ToJson)

///|
pub extend Issue with Eq::{equal, not_equal}

///|
pub extend Report with Eq::{equal, not_equal}

///|
#deprecated("Use Repr(value) instead", skip_current_package=true)
#doc(hidden)
pub extend Issue with Debug::{to_repr}

///|
#deprecated("Use Repr(value) instead", skip_current_package=true)
#doc(hidden)
pub extend Report with Debug::{to_repr}

///|
#deprecated("Use ToJson::to_json instead", skip_current_package=true)
#doc(hidden)
pub extend Issue with ToJson::{to_json}

///|
#deprecated("Use ToJson::to_json instead", skip_current_package=true)
#doc(hidden)
pub extend Report with ToJson::{to_json}

///|
pub fn Report::is_clean(self : Report) -> Bool {
  self.issues.is_empty()
}

///|
pub fn Report::json(self : Report) -> String {
  ToJson::to_json(self).stringify(indent=2)
}

///|
fn blank(input : String) -> Bool {
  for c in input.to_array() {
    // Unicode White_Space, including nonbreaking and full-width spaces.
    let whitespace = ('\t' <= c && c <= '\r') ||
      c == ' ' ||
      c == '\u{85}' ||
      c == '\u{a0}' ||
      c == '\u{1680}' ||
      ('\u{2000}' <= c && c <= '\u{200a}') ||
      c == '\u{2028}' ||
      c == '\u{2029}' ||
      c == '\u{202f}' ||
      c == '\u{205f}' ||
      c == '\u{3000}'
    if !whitespace {
      return false
    }
  }
  true
}

///|
fn add_issue(
  issues : Array[Issue],
  code : String,
  line : Int,
  column : String,
  key : String,
  message : String,
) -> Unit {
  issues.push({ code, line, column, key, message, })
}
