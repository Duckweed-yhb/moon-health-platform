# Changelog

本项目遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，
版本号遵循 [Semantic Versioning](https://semver.org/lang/zh-CN/)。

## [Unreleased]

### Added

- `--moonproof` 接入 `--out JSON` 严格解析：新增 `features/jsonparse`（最小但严格的 JSON 解析器，纯计算、四后端可移植），`run_moonproof` 改为追加 `--out <临时 JSON>` 并解析 MoonProof 报告数组，汇总每个文档块的通过 / 失败 / 总数，文档验证输出真实数字。
- 工程文档：CHANGELOG / CONTRIBUTING / ROADMAP / AI 使用说明。

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
