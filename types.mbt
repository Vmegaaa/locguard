/// A stable diagnostic suitable for both a translator and a CI job.
pub(all) struct Issue {
  code : String
  line : Int
  column : String
  key : String
  message : String
} derive(Eq, Show, ToJson)

/// The number of data records excludes the header, including malformed-width rows.
pub(all) struct Report {
  rows_checked : Int
  source_locale : String
  issues : Array[Issue]
} derive(Eq, Show, ToJson)

pub fn Report::is_clean(self : Report) -> Bool {
  self.issues.is_empty()
}

pub fn Report::json(self : Report) -> String {
  @json.to_json(self).stringify(indent=2)
}

fn blank(input : String) -> Bool {
  for c in input.to_array() {
    if c != ' ' && c != '\t' && c != '\r' && c != '\n' {
      return false
    }
  }
  true
}

fn add_issue(
  issues : Array[Issue],
  code : String,
  line : Int,
  column : String,
  key : String,
  message : String,
) -> Unit {
  issues.push({ code, line, column, key, message })
}
