# 生态对照记录

检索日期：2026-09-30。发现已有国际化与 CSV 质量工具，特别是 `lampclaw/i18n` 已包含未翻译消息检查和带位置的 JSON 诊断。当前证据不能证明 LocGuard 满足赛事的避免相似项目要求，也不能证明已有库完全覆盖 LocGuard 的具体输入与规则。

## 检索范围

在 Mooncakes 官方注册页中检索 `localization`、`localisation`、`i18n`、`placeholder`、`placeholder translation` 和 `CSV validation`，并阅读相关项目的公开 README 与注册页 API。对 `lampclaw/moonbit-i18n` 追加了 `CSV`、`duplicate`、`multiset` 的公开仓库检索。

这是一次有范围的文档核查，没有全量枚举注册表或验证所有源码。部分源文件链接无法读取，公开源码克隆也未成功，因此下面“未确认”不等于“不支持”。没有运行这些第三方项目，也没有比较它们的性能或测试质量。

代码级核查状态：2026-09-30 在授权的联网执行环境中，对 [lampclaw/moonbit-i18n 官方公开仓库](https://github.com/lampclaw/moonbit-i18n) 进行了 1 次 `git clone --depth 1` 尝试。连接代理失败，工具返回非零退出码与 `Could not connect to server`，没有取得源文件，因此无法继续进行计划中的 CSV、duplicate、multiset、placeholder、missing 源码搜索。此次没有获得新的功能支持或缺失证据，也没有执行第三方程序。

## 相关现成项目

| 项目与证据 | 已确认的相关能力 | 对 LocGuard 的影响 |
|---|---|---|
| [lampclaw/i18n 0.9.1 注册页](https://mooncakes.io/docs/lampclaw/i18n%400.9.1)，[0.9.2 源仓库 README](https://github.com/lampclaw/moonbit-i18n) | JSON/schema 的多语言资源流程、MF2、覆盖率门槛，空白消息视为未翻译，文本位置和 JSON 诊断 | 同属本地化领域，缺翻译、定位和 CI 输出存在明确重叠，应优先对照 |
| [Wchwch777/moonverity](https://mooncakes.io/docs/Wchwch777/moonverity) | CSV/JSONL 数据契约与质量检查，必需或可空字段、值类型、范围、枚举与模式约束，CI 命令 | 通用 CSV 校验已有实现，不能把“CSV 检查”本身作为新增价值 |
| [CJR-zhang/mbitsv](https://mooncakes.io/docs/CJR-zhang/mbitsv) | 分隔文本解析、表格 schema 与非空字段规则，重复 key 报告、带行列的解析错误、质量门槛 | 重复 key 和精确错误位置也不是空白领域 |
| [JingLan0v0/moonrow 0.1.0](https://mooncakes.io/docs/JingLan0v0/moonrow%400.1.0) | CSV 表头与字段数校验、按 key 比较表格、文本/JSON/Markdown 输出、CLI 退出码 | JSON 报告与脚本集成已有相邻实践，主要用途是表格差异比较 |
| [moonbit-community/NyaCSV](https://mooncakes.io/docs/moonbit-community/NyaCSV)，[源码](https://github.com/moonbit-community/NyaCSV) | CSV 解析、可配置分隔符与引号、引号内换行 | 已有可考虑复用的解析基础，不能把实现一个 CSV 解析器等同于新的本地化功能 |

## lampclaw/i18n 的三项具体核查

| 需要核查的行为 | 本次能确认的事实 | 未解决项 |
|---|---|---|
| RFC 4180 CSV 输入及检查 | README 明确以 JSON schema 和 locale JSON 为主要编写格式，列出的迁移工具包括 i18next、ARB 和 XLIFF | 未在可读文档确认 CSV 检查入口，未成功完成其相关源码核查 |
| 重复 key | 文档包含消息 ID 与 schema 工作流 | 未确认是否专门检查 CSV key 或 JSON 重复属性，不能写成没有重复检查 |
| `{name}`/`{0}` 的重复次数多重集合比较 | 文档使用 MF2 的 `{$name}` 和声明参数，不是 LocGuard 的简单花括号语法 | 未确认其是否按每个语言字符串的引用次数比较，不能写成已证明不支持 multiset |

上述判断依据是 [README 的编写模型与生成检查说明](https://github.com/lampclaw/moonbit-i18n) 和 [固定版本注册页](https://mooncakes.io/docs/lampclaw/i18n%400.9.1)，不代表全面源码审计。

## LocGuard 可具体说明的用途

当前实现接收一张 `key + 语言列` 的 CSV，不要求先建 schema 或生成应用包。它对简单 `{name}`、`{0}` 保留每次出现并比较多重集合，允许译文调换顺序，同时识别少用或多用占位符。语义诊断关联 key、语言列和 CSV 记录起始物理行号，文本与 JSON 共用同一份检查结果。

这是一种面向 CSV 本地化表的具体组合与规则约定，具有可解释的用途。缺失翻译、错误位置和 JSON CI 诊断单独来看已有重叠，不能包装成首创。对照结果尚不足以判断主办方是否会把这一组合认定为相似项目；申报前应如实披露上述相邻项目与仍未确认的行为，由参赛者或主办方判断资格。
