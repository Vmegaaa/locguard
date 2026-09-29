extern "js" fn arguments() -> FixedArray[String] =
  #|() => process.argv.slice(2)

// The FFI only handles local IO; all CSV and localization logic is MoonBit.
extern "js" fn read_file(path : String) -> FixedArray[String] =
  #|(path) => {
  #|  try {
  #|    const fs = require('node:fs');
  #|    const stat = fs.statSync(path);
  #|    if (!stat.isFile()) return ['', 'Input must be a regular file'];
  #|    if (stat.size > 16 * 1024 * 1024) return ['', 'Input exceeds the 16 MiB CLI limit'];
  #|    return [new TextDecoder('utf-8', {fatal: true}).decode(fs.readFileSync(path)), ''];
  #|  } catch (error) {
  #|    return ['', String(error.message)];
  #|  }
  #|}

extern "js" fn set_exit(code : Int) -> Unit =
  #|(code) => { process.exitCode = code; }

extern "js" fn stderr(message : String) -> Unit =
  #|(message) => { process.stderr.write(message + '\n'); }

struct Options {
  path : String
  source : String?
  json : Bool
} derive(Eq, Show)

fn usage() -> String {
  "LocGuard 0.1.0\nUsage: locguard [--json] [--source LOCALE] [--] FILE.csv\nChecks key uniqueness, missing translations and brace placeholder parity.\nCSV: key,source_locale,translation_locale[,more_locales...]\nSupported placeholders: {name}, {0}; literal braces: {{ and }}.\nExit codes: 0 clean, 1 validation issues, 2 usage or IO error.\nOptions: --help, --version. Node.js 18+ required."
}

fn parse_args(args : FixedArray[String]) -> Result[Options, String] {
  let mut path : String? = None
  let mut source : String? = None
  let mut json = false
  let mut literal = false
  let mut i = 0
  while i < args.length() {
    let arg = args[i]
    if !literal && arg == "--" {
      literal = true
    } else if !literal && arg == "--json" {
      json = true
    } else if !literal && arg == "--source" {
      if source != None { return Err("--source can only be specified once") }
      i += 1
      if i >= args.length() || args[i] == "" || args[i].has_prefix("-") {
        return Err("--source requires a locale name")
      }
      source = Some(args[i])
    } else if !literal && arg.has_prefix("-") {
      return Err("Unknown option: \{arg}")
    } else {
      if path != None { return Err("Expected exactly one input CSV file") }
      path = Some(arg)
    }
    i += 1
  }
  match path {
    Some(path) => Ok({ path, source, json })
    None => Err("Missing input CSV file"),
  }
}

fn main {
  let args = arguments()
  for arg in args {
    if arg == "--" { break }
    if arg == "--help" {
      println(usage())
      return
    }
    if arg == "--version" {
      println("LocGuard 0.1.0")
      return
    }
  }
  let options = match parse_args(args) {
    Ok(options) => options
    Err(message) => {
      stderr(message)
      stderr(usage())
      set_exit(2)
      return
    }
  }
  let read = read_file(options.path)
  if read[1] != "" {
    stderr("Cannot read \{options.path}: \{read[1]}")
    set_exit(2)
    return
  }
  let report = match options.source {
    Some(locale) => @locguard.validate_with_source(read[0], locale)
    None => @locguard.validate(read[0]),
  }
  if options.json {
    println(report.json())
  } else {
    println("Checked \{report.rows_checked} records; source=\{report.source_locale}; issues=\{report.issues.length()}")
    for issue in report.issues {
      println("\{options.path}:\{issue.line} [\{issue.code}] column=\{issue.column} key=\{issue.key}: \{issue.message}")
    }
  }
  set_exit(if report.is_clean() { 0 } else { 1 })
}
