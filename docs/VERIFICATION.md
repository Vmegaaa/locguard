# 本地验证记录

日期：2026-09-30。下面记录实际执行结果，不代表公开 GitHub CI 已运行或赛事已经通过审核。

环境：Windows x86_64；`moon 0.1.20260920 (914d7da 2026-09-20)`；`moonc v0.10.14+7d59c7ec9 (2026-09-18)`；Node.js `v24.19.0`。

官方 Windows 工具链 ZIP 的 SHA-256 与官方 `.sha256` 文件一致：`faae225a8287d0ce69e44b5b3f754af988e97f4446056d8f32ceb3ddb998fce7`。标准库采用同次官方 `core-latest.zip` 并完成 bundle。

| 实际命令 | 结果 |
|---|---|
| `moon check --target js --deny-warn` | 通过，0 警告、0 错误 |
| `moon test --target js --deny-warn` | 36 项测试，36 通过、0 失败 |
| `moon test --target wasm-gc --deny-warn` | 34 项测试，34 通过、0 失败；CLI 仅支持 JS |
| `node scripts/smoke.mjs` | 15 项实际 CLI 集成检查通过 |
| `moon run cmd/main --target js -- examples/valid.csv` | 检查 6 条记录、0 诊断，退出 0 |
| `moon run cmd/main --target js -- --json examples/invalid.csv` | 检查 7 条记录、6 个预期诊断，退出 1 |

CSV 单元测试包含 100 组双字段语料、200 次往返验证断言，覆盖 Unicode、引号、逗号及换行。CLI 集成检查实际启动构建产物，覆盖正常和错误报告、显式源语言、帮助、版本、未知参数、缺文件、目录、非法 UTF-8、CSV 语法错误，以及 `--` 后的字面文件名。

工具链兼容修复包含：使用 `Debug` 测试诊断、当前 match 分支语法、明确的占位符字典序排序，并迁移到官方当前 `moon.mod` / `moon.pkg` 元数据格式。CI 配置提供 Linux 与 Node.js 22 的后续验证，但该环境的结果需以公开运行日志为准。
