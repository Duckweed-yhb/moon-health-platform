# 平台 `--moonproof` 端到端演示报告（归因 + 文档验证）

- 生成日期：2026-10-22
- 工具链：`moon 0.1.20261012` / `--target native`
- 生成方式：用**平台自身 CLI** `moonhealth check --moonproof "..."` 对本地真实项目跑**完整编排**（归因 → MoonProof 文档验证 → JSON 严格解析 → 统一健康报告），不依赖 mock。
- 数据来源：MoonProof CLI 真实产出的 `--out JSON`，平台侧 `features/jsonparse` 严格解析后聚合。

---

## 1. 背景与目标

`--moonproof` 是平台 `check` 命令的可选参数：注入 MoonProof CLI 命令模板后，平台对子进程调用 MoonProof，对目标项目做**文档示例验证**（扫描 `.md` 中的 ` ```moonbit ` 代码块，逐块编译验证），并把结果通过 `--out JSON` 读回，用 `features/jsonparse` 严格解析后并入 `HealthReport`。

在评审四维（技术 30 / 场景 30 / 治理 20 / 长期 20）中的意义：

| 维度 | 本演示的对应 |
|---|---|
| **技术 30** | 展示平台不是单一检查，而是**编排引擎**：归因（moon-hive verify）+ 文档验证（MoonProof）+ JSON 严格解析 + 统一报告，全部在一次 `moonhealth check` 调用内完成。 |
| **场景 30** | "这个包能不能用、文档示例有没有失效"是生态参与者的真实痛点。moon-hive 作为真实本地项目，其文档中 39 个失效块直接证明了文档漂移的普遍性。 |
| **治理 20** | 文档验证结果被纳入 `HealthReport.healthy` 判定（`usable && docs_failed == 0`），文档失效不再是"软提示"而是"硬不健康"。 |
| **长期 20** | MoonProof 通过子进程注入（非编译期依赖），平台自身可移植；MoonProof 本身可独立演进，接口契约为 `--out JSON`。 |

---

## 2. 复现命令

### 2.1 前置条件

```
# MoonProof CLI 仓库（本机已存在）
E:\future\yhb\03-竞赛\MoonBit-Hackathon\2026-09\moonhive备赛\MoonProof

# 目标项目（moon-hive 复制到 ASCII 路径，原因见 §6 局限）
C:\Users\yhb\moonproof-run\moon-hive

# 平台 CLI 二进制
E:\future\yhb\03-竞赛\开放原子大赛\moon-health-platform\_build\native\debug\build\cmd\moonhealth\moonhealth.exe
```

### 2.2 完整命令序列

```powershell
# 步骤 1：从 MoonProof 目录运行平台 CLI（使 moon run --target native cmd/moonproof -- 能找到 moon.mod）
Set-Location 'E:\future\yhb\03-竞赛\MoonBit-Hackathon\2026-09\moonhive备赛\MoonProof'

# 步骤 2：运行 check，注入 moonproof 命令模板，目标为 ASCII 路径的 moon-hive
& 'E:\future\yhb\03-竞赛\开放原子大赛\moon-health-platform\_build\native\debug\build\cmd\moonhealth\moonhealth.exe' `
    check --moonproof "moon run --target native cmd/moonproof --" `
    'C:\Users\yhb\moonproof-run\moon-hive'
```

平台内部构造的最终命令：
```
moon run --target native cmd/moonproof -- C:\Users\yhb\moonproof-run\moon-hive --out C:\Users\yhb\AppData\Local\Temp\moonhealth-docs-<timestamp>.json
```

---

## 3. 平台 CLI 原始输出（真实执行）

```
🔒 moon-hive  →  Unsafe
    含 FFI 或自定义构建脚本，出于安全只做静态分析
    包可用性: 不可用
    文档验证: 3 通过 / 39 失败
    整体健康: ❌ 不健康

===== 平台健康报告 =====
# MoonHealth 生态健康报告

| 对象 | 归因 | 可用 | 文档 | 健康 |
|---|---|---|---|---|
| moon-hive | 🔒 Unsafe | ❌ | 3过/39失 | ❌ |

**统计**：1 个对象，0 个可用，1 个不健康。

JSON: [{"subject":"moon-hive","verdict":"Unsafe","verdict_explain":"含 FFI 或自定义构建脚本，出于安全只做静态分析","verdict_mark":"🔒","usable":false,"docs_passed":3,"docs_failed":39,"has_docs":true,"healthy":false}]
```

> 说明：以上为平台 CLI **一次调用**的完整输出。归因（Unsafe）来自 moon-hive verify；文档验证（3通过/39失败）来自 MoonProof 子进程的 `--out JSON`；两者在 `features/orchestrate` 合并为统一健康报告。

---

## 4. 逐对象解析表

### 4.1 文档级（MoonProof 扫描结果）

MoonProof 扫描了 moon-hive 目录下 33 个 `.md` 文件，其中 6 个含 moonbit 代码块（其余 27 个无代码块）：

| 文档路径 | 总块数 | 通过 | 失败 | 跳过 | 归因分布 |
|---|---|---|---|---|---|
| `README.md` | 2 | 0 | 2 | 0 | api-changed ×1, compile-error ×1 |
| `docs/API.md` | 12 | 1 | 11 | 0 | compile-error ×11 |
| `docs/examples/wasm-consumer/.mooncakes/.../README.md` | 2 | 0 | 2 | 0 | api-changed ×1, compile-error ×1 |
| `docs/examples/wasm-consumer/.mooncakes/.../docs/API.md` | 12 | 1 | 11 | 0 | compile-error ×11 |
| `docs/examples/classify-demo/.mooncakes/.../README.md` | 2 | 0 | 2 | 0 | api-changed ×1, compile-error ×1 |
| `docs/examples/classify-demo/.mooncakes/.../docs/API.md` | 12 | 1 | 11 | 0 | compile-error ×11 |
| **合计** | **42** | **3** | **39** | **0** | |

> 注：后四组是 moon-hive `docs/examples/` 下 `.mooncakes/` 目录中嵌套的 moon-hive 源码副本，MoonProof 递归扫描时一并发现。内容与前两组完全相同（1 通过 + 11 失败 × 2 份，README 0 通过 + 2 失败 × 2 份）。**以上数据为修复前基线**——自 MoonProof `70672a0` 起 `scan_ext` 已排除 `.mooncakes`，此类重复副本不再被扫描（详见 §6）。

### 4.2 块级详情（主文档 `README.md` + `docs/API.md`）

| 文档 | 行号 | 类型 | 状态 | 归因 | 说明 |
|---|---|---|---|---|---|
| `README.md` | 12 | compile | fail | api-changed | 示例引用了不存在的 API（`@diagnose.CheckOutcome`），工具链演进导致 |
| `README.md` | 138 | compile | fail | compile-error | 示例自身有语法/类型错误 |
| `docs/API.md` | 35 | compile | pass | — | `struct CommandOutcome` 定义，编译通过 |
| `docs/API.md` | 47 | compile | fail | compile-error | `struct CheckOutcome` 触发 unused_type_declaration 警告 |
| `docs/API.md` | 65 | compile | fail | compile-error | `pub fn classify` 签名孤立，引用未定义类型 |
| `docs/API.md` | 73 | compile | fail | compile-error | `pub fn classify_verified` 同上 |
| `docs/API.md` | 87 | compile | fail | compile-error | `pub fn explain` 同上 |
| `docs/API.md` | 95 | compile | fail | compile-error | `pub fn evidence` 同上 |
| `docs/API.md` | 103 | compile | fail | compile-error | `pub fn label` 同上 |
| `docs/API.md` | 113 | compile | fail | compile-error | `pub fn is_usable` 同上 |
| `docs/API.md` | 121 | compile | fail | compile-error | `pub fn count_issues` 同上 |
| `docs/API.md` | 129 | compile | fail | compile-error | `pub fn extract_missing_symbols` 同上 |
| `docs/API.md` | 138 | compile | fail | compile-error | `pub fn first_error_line` 同上 |
| `docs/API.md` | 163 | compile | fail | compile-error | 完整示例 import 了 `Duckweed/moon-hive/verify/diagnose`，但独立编译时依赖不可解析 |

### 4.3 平台合并结果

| 字段 | 值 | 来源 |
|---|---|---|
| subject | `moon-hive` | from_local 取目录名 |
| verdict | `Unsafe` | moon-hive verify（含 C FFI） |
| usable | `false` | Unsafe 不是可用结论 |
| docs_passed | `3` | MoonProof JSON 求和（`sum_docs`） |
| docs_failed | `39` | MoonProof JSON 求和 |
| has_docs | `true` | total=42 > 0 |
| healthy | `false` | usable=false（无论文档如何） |

---

## 5. 评审意义

1. **编排引擎而非单一检查**：一次 `moonhealth check --moonproof "..."` 调用内完成：归因（moon-hive verify）→ MoonProof 子进程文档验证 → JSON 严格解析 → 健康判定 → Markdown 报告 + 机器可读 JSON。这不是"包了个壳"，而是两个子工具的**真正编排**。

2. **文档漂移是真实生态问题**：moon-hive 的 `docs/API.md` 12 个代码块中仅 1 个通过（孤立 struct 定义），11 个失败——API 签名散落在文档中作为"参考"，但它们无法独立编译。`README.md` 的 2 个示例也全失败。这证明"文档示例会过期"不是假设，而是需要工具持续验证的现实。

3. **文档验证纳入健康判定**：`HealthReport.healthy = usable && (docs_failed == 0)`。即使包可用，文档示例失效也会导致不健康。这把"文档质量"从软提示提升为硬健康信号。

4. **子进程注入的架构价值**：MoonProof 是 native + C FFI 的 CLI，平台通过子进程调用而非编译期 import，避免了 C FFI 依赖图污染平台的可移植核心（features/jsonparse、orchestrate、report 均为纯计算、全后端覆盖）。

5. **JSON 契约稳定**：MoonProof 输出 `[{path, total, passed, failed, skipped, blocks:[{path, start_line, kind, status, verdict, detail, suggestion}]}]`，平台 `jsonparse` 严格解析并只提取 `total/passed/failed` 求和。字段缺失或类型不符按 0 处理（对无文档项无副作用）。

---

## 6. 局限与后续

### 6.1 本机实测局限

| 局限 | 影响 | 说明 |
|---|---|---|
| **中文路径编码问题** | 首次直接对 `E:\...\moon-hive`（含中文）运行时，平台 C FFI 子进程调用 MoonProof 后 JSON 读取/解析失败，显示"无文档需要验证"。复制到 ASCII 路径 `C:\Users\yhb\moonproof-run\moon-hive` 后正常。 | 根因：平台 `proc_run_capture`（C FFI）在 Windows 上传递含中文的命令字符串时编码丢失。这是已知限制，评审时应说明。 |
| **MoonProof 递归扫描到 .mooncakes 副本**（已修复） | 修复前：扫描出 33 个 `.md`，其中 4 组是 `docs/examples/` 下 `.mooncakes/` 内嵌的源码副本，42 块中有 28 块是重复内容。 | 已于 MoonProof `70672a0` 修复：`scan_ext` 的 `not_build` 增加 `.mooncakes` 排除。修复后此类副本不再被扫描；本条数据为本演示的修复前基线。 |
| **API.md 签名块失败属预期** | 11 个孤立函数签名失败不是因为代码写错，而是因为它们是"API 参考"而非可独立编译的完整程序。 | 这是文档形式的局限：纯签名展示在 MoonProof 模型下会失败。后续可支持 ` ```moonbit no-check ` 标注或文档专用的签名验证模式。 |
| **GitHub 网络间歇不可达** | 本演示全部使用本地候选，不涉及远端 clone。 | 与 check-batch 报告一致。 |

### 6.2 后续方向

- **中文路径修复**：在平台 `proc_run_capture` 的 C 代码中使用 UTF-8 → 系统 ANSI 转换（或直接用宽字符 API），消除中文路径下的编码丢失。
- **`.mooncakes` 排除**：✅ 已实现（MoonProof `70672a0`，`not_build` 增加 `.mooncakes` 排除）；重跑 `--moonproof` 可得到排除重复副本后的更干净数据。
- **多候选对比**：本演示单候选；后续可对一批本地包跑 `--moonproof`，展示跨包的文档健康分布。
- **`--dep` 注入**：MoonProof 支持 `--dep owner/name`，平台可透传，让文档示例 import 外部包时也能编译。
