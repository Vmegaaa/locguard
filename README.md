# LocGuard

用 MoonBit 检查游戏和应用的本地化 CSV：重复 key、缺失翻译，以及跨语言的占位符遗漏或重复。文件留在本地，无需账户或外部云服务。

开发状态：初始实现。下列命令是预期的使用方式，提交前需以实际运行和 CI 结果核实。本文不代表测试已经通过。

## 快速开始

安装 [MoonBit 工具链](https://docs.moonbitlang.com/en/stable/tutorial/tour.html) 和 Node.js，在项目根目录运行：

```sh
moon test
moon run cmd/main --target js -- examples/valid.csv
moon run cmd/main --target js -- --json examples/invalid.csv
```

显式选择源语言列：

```sh
moon run cmd/main --target js -- --source en_US examples/valid.csv
moon run cmd/main --target js -- --help
moon run cmd/main --target js -- --version
```

纯 MoonBit 核心库处理 CSV 和检查规则。命令行使用 JavaScript 后端，通过少量 Node.js 文件读取与参数接口访问本地文件。

## 输入格式

使用 UTF-8 CSV，首行为表头。第一列必须叫 `key`，后面至少有两个语言列，列名不能为空或重复。默认第二列是源语言，`--source` 可以选择其他语言列。

```csv
key,zh_CN,en_US
ui.start,开始游戏,Start game
ui.welcome,欢迎你，{name}！,Welcome {name}!
score.summary,得分：{0},Score: {0}
```

CSV 引号字段可以包含逗号和换行，字段内双引号以 `""` 转义。每条记录的字段数应与表头一致。

## 检查内容

- CSV 结构、表头和记录字段数。
- 空 key 与重复 key。
- 空白源文本或翻译。
- `{name}`、`{0}` 形式的占位符名称和出现次数。

占位符按多重集合比较，允许译文调整顺序。例如源文本出现两次 `{name}`，译文也必须出现两次。诊断包含错误所在行及语言列，便于定位原文件。文本输出供人工阅读，`--json` 供脚本或 CI 收集结果。

退出码：`0` 表示没有诊断，`1` 表示存在检查问题，`2` 表示参数或文件读取错误。

`examples/valid.csv` 演示正常内容、引号转义及占位符顺序调整。`examples/invalid.csv` 有意包含重复 key、缺失翻译、占位符名称和次数不一致，可以用于演示错误诊断。所有名称和数据均为虚构。

## 范围与限制

LocGuard 检查表格结构与占位符一致性，不判断翻译质量。当前范围不支持 ICU MessageFormat、复数或性别表达式、嵌套占位符，以及 `{0:N2}` 等 format specifier。它也不读取 XLSX、JSON、PO 或引擎专属资源格式。

程序不发起外部云调用，不上传 CSV。CLI 输出可能包含文件路径、key 或诊断信息，发布 CI 日志前请自行确认输入不含私人内容。仓库样例只使用虚构信息。

## 生态与设计

MoonBit 社区已有 [NyaCSV](https://github.com/moonbit-community/NyaCSV) 等 CSV 解析项目。LocGuard 的用途是检查本地化表格的语义约束，提供可复用的检查核心和适合 CI 的诊断输出。这里不主张它是生态中的唯一或首个此类项目。

最小范围先围绕小型 UTF-8 本地化表建立可复现的测试。后续可以根据实际问题讨论其他资源格式或与现有解析库集成，不承诺尚未实现的功能或性能。

## 许可与 AI 使用

项目采用 [Apache License 2.0](LICENSE)。开发中使用 AI 辅助的范围和验证责任见 [AI_USAGE.md](AI_USAGE.md)。赛事要求申报正文由参赛者本人撰写，[申报准备模板](PROPOSAL_TEMPLATE.zh-CN.md) 仅提供事实字段和写作提示，不能作为已完成的人工申报书直接提交。
