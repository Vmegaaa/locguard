import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const moon = process.env.MOON_BIN || 'moon';
const build = spawnSync(moon, ['build', 'cmd/main', '--target', 'js'], { cwd: root, encoding: 'utf8' });
assert.equal(build.status, 0, `CLI build failed: ${build.error || build.stderr || build.stdout}`);

function findMain(directory) {
  if (!fs.existsSync(directory)) return [];
  return fs.readdirSync(directory, { withFileTypes: true }).flatMap(entry => {
    const name = path.join(directory, entry.name);
    if (entry.isDirectory()) return findMain(name);
    if (/[/\\]cmd[/\\]main[/\\]main\.(?:c?js|mjs)$/.test(name)) return [name];
    return [];
  });
}
const artifacts = ['_build', 'target'].flatMap(folder => findMain(path.join(root, folder)));
assert.equal(artifacts.length, 1, `Expected one CLI build artifact, found: ${artifacts}`);
const binary = artifacts[0];
let checked = 0;
function run(args, exitCode, cwd = root) {
  const result = spawnSync(process.execPath, [binary, ...args], { cwd, encoding: 'utf8' });
  assert.equal(result.status, exitCode, `Unexpected exit for ${args}: ${result.error || result.stderr || result.stdout}`);
  checked++;
  return result;
}

const valid = JSON.parse(run(['--json', 'examples/valid.csv'], 0).stdout);
assert.equal(valid.rows_checked, 6);
assert.deepEqual(valid.issues, []);
assert.equal(valid.source_locale, 'zh_CN');

const invalid = JSON.parse(run(['--json', 'examples/invalid.csv'], 1).stdout);
for (const code of ['duplicate_key', 'missing_translation', 'placeholder_mismatch']) {
  assert(invalid.issues.some(issue => issue.code === code), `Missing diagnostic: ${code}`);
}
assert.equal(run(['--json', 'examples/invalid.csv'], 1).stdout, JSON.stringify(invalid, null, 2) + '\n');
assert.match(run(['--source', 'en_US', 'examples/valid.csv'], 0).stdout, /source=en_US/);
assert.match(run(['--help'], 0).stdout, /Usage:/);
assert.match(run(['--version'], 0).stdout, /0\.1\.0/);
assert.match(run([], 2).stderr, /Missing input/);
assert.match(run(['--unknown'], 2).stderr, /Unknown option/);
assert.match(run(['--source', '--json', 'examples/valid.csv'], 2).stderr, /locale name/);
assert.match(run(['not-a-real-file.csv'], 2).stderr, /Cannot read/);
assert.match(run(['examples'], 2).stderr, /regular file/);

const tempRoot = fs.realpathSync(os.tmpdir());
const scratch = fs.mkdtempSync(path.join(tempRoot, 'locguard-smoke-'));
const safeScratch = fs.realpathSync(scratch);
assert.equal(path.dirname(safeScratch), tempRoot);
try {
  const nonUtf8 = path.join(scratch, 'invalid-utf8.csv');
  fs.writeFileSync(nonUtf8, Buffer.from([0x6b, 0x65, 0x79, 0x2c, 0xff]));
  assert.match(run([nonUtf8], 2).stderr, /Cannot read/);
  const malformed = path.join(scratch, 'quoted.csv');
  fs.writeFileSync(malformed, 'key,en_US,zh_CN\na,"unclosed,你好');
  const report = JSON.parse(run(['--json', malformed], 1).stdout);
  assert.equal(report.issues[0].code, 'csv');
  assert.equal(report.issues[0].line, 2);
  for (const filename of ['--help', '--version']) {
    fs.writeFileSync(path.join(safeScratch, filename), 'key,en_US,zh_CN\na,Hi,你好\n');
    assert.equal(JSON.parse(run(['--json', '--', filename], 0, safeScratch).stdout).rows_checked, 1);
  }
} finally {
  // Only remove the exact temporary directory created above.
  fs.rmSync(safeScratch, { recursive: true, force: true });
}
console.log(`CLI integration checks passed: ${checked}`);
