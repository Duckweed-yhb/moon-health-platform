# Changelog

本项目遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，
版本号遵循 [Semantic Versioning](https://semver.org/lang/zh-CN/)。

## [Unreleased]

### Added

- `--moonproof` 接入 `--out JSON` 严格解析：新增 `features/jsonparse`（最小但严格的 JSON 解析器，纯计算、四后端可移植），`run_moonproof` 改为追加 `--out <临时 JSON>` 并解析 MoonProof 报告数组，汇总每个文档块的通过 / 失败 / 总数，文档验证输出真实数字。
- 工程文档：CHANGELOG / CONTRIBUTING / ROADMAP / AI 使用说明。
- 测试补强：编排合并逻辑边界用例（`healthy` 真值表、`render_health` 分支、`render_markdown` 无文档/有文档/多对象/空数组、`summarize` 空数组与失败块累加、`to_json` 包不可用字段、`escape` Unicode），测试数 18 → 34。
- 生态普查：`survey --registry` 对 mooncakes **48 个真实发布包**实测，可用率 27.1%（13/48），报告见 `docs/ecosystem-survey-2026-10.md`（对比 2026-09 的 18 包基线 16.7%）。
- 开源治理：新增 `CODE_OF_CONDUCT`、`ISSUE_TEMPLATE`（bug / feature / config）、`PULL_REQUEST_TEMPLATE`、`SECURITY`、`docs/RELEASING`。
- 对标实证：并跑 `Tino-hue/depsight`（生态依赖健康工具，输出 0–100 健康分）与 MoonHive 对 8 个代表发布包打分对比，验证「depsight 健康分高 ≠ 本机可编译」的互补定位——yacc / base64 在 depsight 拿 98 / 96 分却在本机工具链上编译不过，见 `docs/ecosystem-survey-2026-10.md`。
- 联动 `moon-hive` 上游修复：proc 层实现真正的进程级超时（fetch 挂起不再永久卡死，实测 mooncrypt 2.4s 归 ToolchainMismatch、mooncry 40.8s 归 TimedOut）。修复位于 moon-hive 源码仓库，`moon-health-platform` 的 moon-hive@0.2.4 依赖副本待上游发布后升级。
- 评审叙事与可持续性：`docs/ecosystem-survey-2026-10.md` 补「结论与评审意义」（把 48 包普查提炼为评审洞察：生态问题真实有规模、静态健康分不足以支撑决策、平台填补统一健康信号空白）；README 新增「项目可持续性」章节（依赖锁定、验证后端可解耦、平台能力独立演进、开源治理）；ROADMAP 更新演进原则与完成状态。
- 平台 `survey` 子命令：复用 moon-hive `features/survey` 做批量生态普查，`--registry` 从 mooncakes 注册表验证发布版本（不依赖 GitHub 克隆），支持 `--out-md` / `--out-json` 输出报告——平台可自产生态普查报告。实测在 2026-10-12 工具链下 `gmlewis/base64` 由 DoesNotCompile 变为 Verified，印证"结论绑定工具链版本"的平台价值。

### Fixed

- `features/jsonparse`：`\uXXXX` 逐 nibble 校验，任一非十六进制即报错（修复 `\u12g4` 被静默接受）；代理对合并（`\uD83D\uDE00` 合并为单个补充字符，孤立/错配代理报错）。
- `features/report`：`render_markdown` 表格单元格转义（竖线 `\|`、换行替换为空格），修复单元格含 `|`/换行破坏表格结构与列数的问题。

### Known Issues

- 本地在含中文的目录跑 native 测试可能触发 gcc 汇编器无法生成 `.obj` 的中文路径编码问题；可用 `moon test --target wasm-gc` 验证纯计算模块（CI 在无中文路径无此问题）。

## [0.1.0] - 2026-10-10

### Added

- 平台骨架：`moonhealth` CLI（check / doctor / version / help）。
- 编排层 `features/orchestrate`：`HealthReport` 数据模型 + 合并逻辑（纯计算、四后端可移植）。
- 报告层 `features/report`：Markdown / JSON / 统计渲染。
- 归因：复用 MoonHive 的 `verify/diagnose` 九类归因引擎（Verified / TestFailing / DoesNotCompile / ToolchainMismatch / MissingDependency / NoManifest / TimedOut / Unsafe / FetchFailed）。
- 文档验证（可选）：`--moonproof` 注入 MoonProof CLI。
- CI：Linux / Windows 矩阵，覆盖检查、构建、测试。
- 依赖：moon-hive@0.2.4（含中文路径 fs 宽字符支持）。

### Fixed

- CI 构建前先 `moon update` 同步 registry 索引，修复依赖解析失败（"module was not found in the registry"）。
