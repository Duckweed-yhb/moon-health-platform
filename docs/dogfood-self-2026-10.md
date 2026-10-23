# 平台自举证据：用 MoonHealth 验证 MoonHealth 自身仓库

> 执行时间：2026-10-23（周五）17:59 CST（UTC+8）
> 验证对象：`E:\future\yhb\03-竞赛\开放原子大赛\moon-health-platform`（本仓库）
> 验证工具链：`C:\Users\yhb\.moon\bin\moon.exe`，版本 `moon 0.1.20261012 (748b63c 2026-10-12)`
> 本文档为"平台用自己的工具验证自己源码"的真实执行记录，所有原始输出均为逐字摘录，未做改写。

---

## 一、复现命令

### 1.1 环境与版本信息

工作目录：`E:\future\yhb\03-竞赛\开放原子大赛\moon-health-platform`（仓库根）

```powershell
Set-Location "E:\future\yhb\03-竞赛\开放原子大赛\moon-health-platform"
git rev-parse HEAD
git status --short
& "C:\Users\yhb\.moon\bin\moon.exe" version
```

实际输出（逐字）：

```
7d09a3b7be9ecfd7262b77a636c7437a05d3210c
moon 0.1.20261012 (748b63c 2026-10-12)

Feature flags enabled: rr_moon_mod,rr_moon_pkg
```

- 验证快照 HEAD：`7d09a3b7be9ecfd7262b77a636c7437a05d3210c`（短哈希 `7d09a3b`，与预期一致）。
- `git status --short` 无输出，执行前工作树干净。
- **未发生 ASCII 路径复制**：原中文路径下 check 直接跑通，未触发 proc 层编码问题，故无需复制到 `C:\Users\yhb\selfdog-run\`（详见"局限与后续"）。

### 1.2 主验证命令：对本仓库跑 check

```powershell
Set-Location "E:\future\yhb\03-竞赛\开放原子大赛\moon-health-platform"
& "C:\Users\yhb\.moon\bin\moon.exe" run cmd/moonhealth --target native -- check "E:\future\yhb\03-竞赛\开放原子大赛\moon-health-platform"
"EXITCODE=$LASTEXITCODE"
```

### 1.3 观察性命令：带 --moonproof

```powershell
& "C:\Users\yhb\.moon\bin\moon.exe" run cmd/moonhealth --target native -- check --moonproof "E:\future\yhb\03-竞赛\开放原子大赛\moon-health-platform"
"EXITCODE=$LASTEXITCODE"
```

---

## 二、CLI 原始输出摘录

### 2.1 主验证命令（退出码 1）

```
🔒 moon-health-platform  →  Unsafe
    含 FFI 或自定义构建脚本，出于安全只做静态分析
    包可用性: 不可用
    文档验证: 无文档需要验证
    整体健康: ❌ 不健康

===== 平台健康报告 =====
# MoonHealth 生态健康报告

| 对象 | 归因 | 可用 | 文档 | 健康 |
|---|---|---|---|---|
| moon-health-platform | 🔒 Unsafe | ❌ | — | ❌ |

**统计**：1 个对象，0 个可用，1 个不健康。


JSON: [{"subject":"moon-health-platform","verdict":"Unsafe","verdict_explain":"含 FFI 或自定义构建脚本，出于安全只做静态分析","verdict_mark":"🔒","usable":false,"docs_passed":0,"docs_failed":0,"has_docs":false,"healthy":false}]
EXITCODE=1
```

### 2.2 --moonproof 观察命令（退出码 14）

```
用法: moonhealth check [--moonproof <cmd>] <候选>...

示例: moonhealth check moonbit-community/yaml
      moonhealth check ./local-pkg --moonproof "moon run --target native C:/path/MoonProof/cmd/moonproof --"
EXITCODE=14
```

> 说明：`--moonproof` 不是布尔开关，而是"后跟一条子进程命令"的选项。本次直接传 `--moonproof` 未接命令，CLI 按参数解析失败退出 14（用法错误）。MoonProof CLI 已归档、本地未检出仓库，按任务边界不修复、不深究，仅记录该用法事实。

---

## 三、结论：平台对自身仓库的归因与健康判定

### 3.1 判定结果

| 字段 | 值 |
|---|---|
| subject | `moon-health-platform` |
| verdict | `Unsafe`（🔒） |
| verdict_explain | 含 FFI 或自定义构建脚本，出于安全只做静态分析 |
| usable | `false` |
| docs_passed / docs_failed / has_docs | 0 / 0 / `false` |
| healthy | `false` |
| 退出码 | `1` |

### 3.2 推导依据（从字段到结论的链条）

1. **判定短路在"安全"档**。本仓库 `moon.mod` 声明 `import { "Duckweed/moon-hive@0.2.4" }`；进入 `.mooncakes/Duckweed/moon-hive/platform/` 可见 FFI 平台桩 `fs_stub.c`、`http_stub.c`、`proc_stub.c`。归因引擎（moon-hive 0.2.4）在判定顺序中先排前提（NoManifest）、再排安全（含 FFI → Unsafe），即命中 FFI 后直接短路，**不再发起 native build/test、不再调用 proc 层**。
2. **因此 `usable=false`**。报告第二行"包可用性: 不可用"与 JSON 字段 `usable:false` 一致；这不是"编译失败"，而是"出于安全保守策略不进入编译"。
3. **因此 `docs_passed=0 / docs_failed=0 / has_docs=false`**。未带 `--moonproof` 子命令，文档验证阶段未触发；`has_docs=false` 是平台对"未请求文档验证"的归一化（与叙事中"防造假"一致），不代表仓库没有 docs/。
4. **因此 `healthy=false`**。`healthy` 是 `usable && docs 全过` 的合取；`usable=false` 即整体不健康。退出码 1 与 CLI 契约"check 任一对象不健康 → 1"一致。
5. **结论一句话**：MoonHealth 平台用自己的归因引擎，对自己的源码仓库得出"🔒 Unsafe / 不可用 / 不健康"的判定——**这个判定不是"平台跑不起来"，而是平台的安全保守策略正确地把"自身依赖了含 FFI 桩的 moon-hive"这件事如实标成了 Unsafe**。这与 `docs/submission-narrative-2026-10.md` 中"--moonproof 端到端对真实项目实测合并判定 Unsafe → 不健康"的口径一致，且本次是在**本仓库自身**上复现。

---

## 四、四维评审意义：为什么"平台验证自身"是场景落地最强证据

术语对齐 `docs/submission-narrative-2026-10.md` 的四维框架（技术 / 场景 / 治理 / 长期），但结论独立推导。

### 4.1 技术维度：严谨性工程化的自证

- 平台不是"静态打分"，而是**在用户自己安装的工具链上（moon 0.1.20261012）真实跑一遍**再下结论。本次对本仓库的判定，是在**同一份工具链、同一份依赖锁定（moon-hive 0.2.4）**上跑出来的，结论可复现、可被任何人用相同命令复跑。
- 判定短路位置（FFI → Unsafe）与 README 描述的判定顺序（NoManifest → Unsafe → 超时 → 后端不匹配 → check 失败 → test）逐字对齐；JSON 字段 `verdict / verdict_explain / usable / has_docs / healthy` 一一对应，证明"严格解析别人的 JSON"与"严格产出自己的 JSON"在自举场景下闭环。
- 测试数（预期 75、native + wasm-gc 双后端全绿）见 README；本次为代码健康判定，未重跑测试。

### 4.2 场景维度：证据链的最诚实一环

- 平台此前的证据链是"对 48 个生态包普查、对 6 个候选 check、对真实项目 --moonproof 端到端"。本次新增**对自己仓库**的 check，是证据链中最容易被质疑"是不是只挑好看的说"的一环——平台把自己的源码也扔进同一个判定流程。
- 结果是 **Unsafe / 不健康**，不是"自己测自己全绿"的自吹自擂。这恰恰证明：归因引擎不因为被测对象是"自己人"就放水；安全保守策略对自身仓库一视同仁。
- 这与叙事中"与第三方对照（depsight）静态分高 ≠ 能跑"的论点呼应：**静态健康分可以对自己打高分，真实工具链判定却会把含 FFI 依赖的自己标成 Unsafe**——这正是平台存在的理由。

### 4.3 治理维度：可接手、可复核

- 复现命令完整、工作目录、版本、HEAD、退出码全部记录在案；任何人在装有同版本 moon 的机器上跑同一条命令应得到同一份判定（差异仅在 `moon.mod` 锁定版本与 `.mooncakes` 缓存）。
- 本次只新增 `docs/dogfood-self-2026-10.md`，不动代码、不动 `.moon` 配置、不动 CI；并行任务正在更新 `docs/submission-narrative-2026-10.md`，本报告不触碰它、不依赖其内容。
- 归档依赖（moon-hive 0.2.4、MoonProof）不修改、不升级，边界与叙事一致。

### 4.4 长期维度：价值不绑定单一工具

- 平台的核心是"编排 + 报告 + 严格 JSON 解析 + CLI"，归因引擎是库方式 import 的 moon-hive，文档验证是子进程调用的 MoonProof。本次自举验证中，归因引擎正确短路、报告层正确渲染、JSON 正确输出——**编排层独立演进的价值在自举场景下被验证**。
- 即便未来替换归因引擎或文档验证器，本报告记录的"用同一 CLI 入口、同一报告格式验证自身仓库"的复现方法仍然成立。

---

## 五、局限与后续

1. **中文路径是否触发 proc 层编码问题：本次未触发。** 原因是判定短路在 FFI 静态检测，**根本没有进入 native build/test / proc 子进程阶段**，因此未触发 README 中提到的"gcc 汇编器无法生成 `.obj` 的中文路径编码问题"。这与叙事中"中文路径下 proc 层编码丢失需 ASCII 路径缓解"不矛盾——那条局限针对的是**需要进入 proc 层**的场景（Verified/TestFailing 等需要编译测试的判定）；本次 Unsafe 短路不涉及 proc。因此本次**未复制到 ASCII 路径**，也无需记录复制时刻与复制快照 commit。
2. **退出码语义**：本次主命令退出码 `1`（不健康），与 CLI 退出码契约一致（见 `docs/cli-smoke-2026-10.md`）；`--moonproof` 用法错误退出码 `14` 与契约一致。
3. **快照漂移**：执行时刻 2026-10-23 17:59 CST，HEAD `7d09a3b`。并行任务正在更新 `docs/submission-narrative-2026-10.md`，该文档级改动不影响代码健康判定（代码未动、`moon.mod` 未动、依赖未动）。
4. **归档依赖边界**：moon-hive 0.2.4（库 import，已归档）、MoonProof（子进程调用，已归档）本次均未修改、未升级；`--moonproof` 用法错误（退出码 14）按任务边界不修复、不深究。
5. **文档验证未触发**：未带 `--moonproof <cmd>` 子命令，故 `docs_passed=0 / docs_failed=0 / has_docs=false`；如需在本仓库上观察文档验证，需另行检出 MoonProof 并按示例拼接子进程命令。
6. **Unsafe 判定的含义边界**：`Unsafe` 是"出于安全保守策略不进入编译"，**不是"平台跑不起来"**——平台自身在本机可正常 `moon run cmd/moonhealth` 启动并产出报告。这是安全策略对自身依赖树（含 FFI 桩）的如实标注。

---

## 附：本次实际执行的命令清单

| # | 命令（工作目录均为仓库根） | 退出码 |
|---|---|---|
| 1 | `git rev-parse HEAD` | 0 |
| 2 | `git status --short` | 0（无输出） |
| 3 | `moon.exe version` | 0 |
| 4 | `moon.exe run cmd/moonhealth --target native -- check "<repo>"` | **1** |
| 5 | `moon.exe run cmd/moonhealth --target native -- check --moonproof "<repo>"` | **14** |
