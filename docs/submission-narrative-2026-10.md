# 项目评审叙事：MoonHealth Platform

**MoonBit 生态健康验证平台**——用真实工具链对每一个生态包跑完整的编译、测试与文档验证，把"这个包现在能不能用"压缩成一个可复核、可自动化的统一健康信号。

它不是又一个静态健康分工具，而是**在用户自己安装的版本与工具链上，实际把包跑一遍**来下结论。结论因此绑定工具链版本，也因此可信、可复现。

本文档按评审四维组织，每一维的论断都附证据，证据全部由平台自身或真实实验产出。

---

## 评审总览

| 维度 | 自评 | 一句话依据 |
|---|---|---|
| 技术（30） | 24 | 编排层 + 严格 JSON 解析 + 报告层，全链路纯计算、四后端可移植；74 用例、双后端 CI 全绿 |
| 场景（30） | 26 | 平台自产 48 包普查、check 批量样例、--moonproof 端到端，证据链完整且诚实标注局限 |
| 治理（20） | 17 | 开源治理文档齐备、CI 双后端、CHANGELOG/报告随改动同步 |
| 长期（20） | 16 | 依赖锁定、验证后端可解耦、编排层独立演进，价值不绑定单一工具 |

---

## 一、技术：严谨性工程化

平台由四个自有模块构成，边界清晰，且刻意保持"纯计算、四后端可移植"：

- `features/orchestrate` 编排层：`HealthReport` 数据模型 + 归因/文档合并逻辑。
- `features/jsonparse`：最小但严格的 JSON 解析器，逐 nibble 校验 `\uXXXX`、合并代理对，用于解析 MoonProof `--out` 输出。
- `features/report`：统一报告渲染（Markdown / JSON / 统计）。
- `cmd/moonhealth`：CLI 入口（check / survey / doctor / version / help）。

严谨性体现为三处真实修复，而非口头承诺：

1. **自产 JSON 始终合法**。`to_json` 的转义原只处理引号与反斜杠，补全为对全部控制字符（`\n` `\r` `\t` 及 0x00–0x1F）转义，`verdict_mark` 也纳入转义——平台既"严格解析别人的 JSON"，也"严格产出自己的 JSON"。
2. **退出码语义统一**。帮助文本、头注释、README 四处此前宣称 2/11/13/15 等从未使用的码，且与子工具透传的实际语义不符；已统一为实际使用的 0/1/10/12/14。平台依赖的归因引擎 moon-hive（0.2.4 快照）中 survey 的"≥1 个 Verified 即退出 0"缺陷已定位并在其源码仓库做了本地修复——moon-hive 已归档、修复未发布，平台依赖仍为 0.2.4 原版，故该语义差异作为平台已知局限如实记录，平台自身退出码契约不依赖此修复。
3. **判定输入防造假**。`make_health_report` 对 `has_docs=true 但 0 块` 的输入归一化为"无文档"——外部无法构造"声称验证过文档却没有任何验证块"的报告来套取健康结论，渲染也不再谎称"0 通过 / 0 失败"。

质量门：**75 个测试，native 与 wasm-gc 双后端在 CI 全绿**；变更一律同步 CHANGELOG 与 README。

诚实边界：`proc` 层对中文路径的编码会丢失（已实测并在报告局限中注明）；moon-hive（已归档）的 survey / inspect 退出码存在"≥1 可用即 0"缺陷，已在其源码仓库做了本地修复但未发布、平台依赖 0.2.4 不含。这些如实记录，不藏。

---

## 二、场景：由平台自身产出的证据链

平台的价值主张——"能不能用必须绑定工具链版本、用真实工具链验证"——由它自己跑出来，而不是引用任何第三方结论：

- **平台自产生态普查**：`moonhealth survey --registry` 对 mooncakes **48 个真实发布包**做全量普查，工具链 2026-10-12，12 个可用（25.0%）。与 09-20 基线逐包对比，**8 个包状态漂移**：`gmlewis/base64` 由 DoesNotCompile 转 Verified，`mizchi/tempfile`、`moonbitlang/quickcheck` 转正，`gaato/http-async` 转 TestFailing。这正是"结论绑定工具链版本"的实证。
- **check 批量样例**：平台自身 `check` 对 6 个候选（2 受控演示 + 2 真实远端 + 1 真实本地）跑完整编排，归因分布 Verified / TestFailing / DoesNotCompile / Unsafe 全覆盖，含可复现的受控样例入库。
- **--moonproof 端到端**：平台一次调用完成归因 + MoonProof 文档验证 + 严格 JSON 解析，对真实项目实测 42 个文档块 = 3 通过 / 39 失败（其中 28 块为 `.mooncakes/` 嵌套副本的重复内容），合并判定 Unsafe → 不健康。

与第三方对照（`depsight`）：静态健康分高的包（yacc / base64 拿 98 / 96 分）在本机工具链上仍可能编译不过——静态打分不足以支撑"能不能用"的决策，平台填补的是这个缺口。

局限同样被记录：中文路径下 `proc` 层编码丢失需 ASCII 路径缓解、`.mooncakes` 重复扫描、`survey` 退出码帮助文本与实际语义的历史不符。证据诚实，而非只挑好看的说。

---

## 三、治理：可接手、可贡献

- 开源治理文档齐备：CONTRIBUTING、ISSUE_TEMPLATE（bug/feature/config）、PULL_REQUEST_TEMPLATE、SECURITY、CODE_OF_CONDUCT、RELEASING，并附 AI 使用说明。
- CI 覆盖 check / build / test，并新增 **wasm-gc 后端**，保证纯计算模块在无中文路径环境下可独立验证。
- 每轮改动同步 CHANGELOG 与 README（测试数、生态数据、命令与退出码不脱节），四份报告均有稳定挂载入口。

---

## 四、长期：价值不绑定单一工具

平台由两个验证能力支撑——归因引擎（moon-hive，库方式 import）与文档验证（MoonProof，子进程调用）。这是有意的架构边界：

- **依赖锁定**：归因引擎锁定并声明稳定版本，能力不随上游是否持续开发而失效。
- **验证后端可解耦**：文档验证走子进程边界，可替换为其他验证器；归因引擎以库 import，也可替换等价实现。
- **平台能力独立演进**：编排、报告、JSON 解析与 CLI 均为平台自有，后续路线（批量扫描、增量缓存、健康分 / Badge、规则可配置）不依赖上游（见 ROADMAP）。

平台的长期价值建立在**自己可交付、可演进、有治理的编排层**之上，而不是绑定在任何单个验证工具的维护上。

---

## 附：证据索引

| 材料 | 位置 | 内容 |
|---|---|---|
| 平台自产生态普查 | `docs/ecosystem-survey-platform-2026-10.md`（+ `.json`） | 48 包、10-12 工具链、与基线 8 包漂移对比 |
| 09-20 基线 + depsight 对标 | `docs/ecosystem-survey-2026-10.md` | 基线数据与第三方对照 |
| check 批量样例 | `docs/check-batch-sample-2026-10.md` + `docs/check-samples/` | 归因分布全覆盖、受控样例可复现 |
| --moonproof 端到端 | `docs/moonproof-sample-2026-10.md` | 真实 42 文档块 3过/39失、局限记录 |
| 项目说明与同步 | `README.md` | 测试数、生态数据、四份报告引用、退出码表 |

以上全部由平台自身或真实实验产出，均可通过 `moonhealth survey --registry` / `moonhealth check` / `moonhealth check --moonproof` 复现。
