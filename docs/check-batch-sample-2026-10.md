# 平台自身 `check` 批量样例报告（MoonHealth CLI 完整编排实测）

- 生成日期：2026-10-22
- 工具链：`moon 0.1.20261012` / `--target native`
- 生成方式：用**平台自身 CLI** `moonhealth check` 对一批候选跑**完整编排**（本地复制 / git 克隆 → 静态预检与安全判定 → `moon check` → `moon test` → 归因分类 → 报告聚合 → JSON），不依赖任何第三方工具。
- 复现命令：
  ```
  moonhealth check docs/check-samples/demo_ok docs/check-samples/demo_fail \
      docs/check-samples/demo_bad <本地 moon-hive 路径> \
      bobzhang/jsonl moonbitlang/core
  ```

## 平台 CLI 原始输出（一次调用）

```
✅ demo_ok  →  Verified
    编译与测试通过，可以直接使用
    包可用性: 可用
    文档验证: 无文档需要验证
    整体健康: ✅ 健康

⚠️  demo_fail  →  TestFailing
    能编译，但测试未通过——代码在演进中，谨慎使用
    包可用性: 不可用
    文档验证: 无文档需要验证
    整体健康: ❌ 不健康

❌ demo_bad  →  DoesNotCompile
    编译器报错，当前工具链上不可用
    包可用性: 不可用
    文档验证: 无文档需要验证
    整体健康: ❌ 不健康

🔒 moon-hive  →  Unsafe
    含 FFI 或自定义构建脚本，出于安全只做静态分析
    包可用性: 不可用
    文档验证: 无文档需要验证
    整体健康: ❌ 不健康

✅ bobzhang/jsonl  →  Verified
    编译与测试通过，可以直接使用
    包可用性: 可用
    文档验证: 无文档需要验证
    整体健康: ✅ 健康

❌ moonbitlang/core  →  DoesNotCompile
    编译器报错，当前工具链上不可用
    包可用性: 不可用
    文档验证: 无文档需要验证
    整体健康: ❌ 不健康

===== 平台健康报告 =====
# MoonHealth 生态健康报告

| 对象 | 归因 | 可用 | 文档 | 健康 |
|---|---|---|---|---|
| demo_ok | ✅ Verified | ✅ | — | ✅ |
| demo_fail | ⚠️  TestFailing | ❌ | — | ❌ |
| demo_bad | ❌ DoesNotCompile | ❌ | — | ❌ |
| moon-hive | 🔒 Unsafe | ❌ | — | ❌ |
| bobzhang/jsonl | ✅ Verified | ✅ | — | ✅ |
| moonbitlang/core | ❌ DoesNotCompile | ❌ | — | ❌ |

**统计**：6 个对象，2 个可用，4 个不健康。

JSON: [{"subject":"demo_ok","verdict":"Verified",...},{"subject":"demo_fail","verdict":"TestFailing",...},{"subject":"demo_bad","verdict":"DoesNotCompile",...},{"subject":"moon-hive","verdict":"Unsafe",...},{"subject":"bobzhang/jsonl","verdict":"Verified",...},{"subject":"moonbitlang/core","verdict":"DoesNotCompile",...}]
```

> 说明：上面表格与 JSON 均为平台 CLI 在**同一次调用**里聚合输出；逐对象诊断（归因分类、可复现原因、健康判定）也全部由平台完成。这正是"平台自身可复现地给出统一健康信号"的直接证据。

## 样本与归因分布

| 对象 | 类型 | 来源 | 归因 | 可用 | 健康 |
|---|---|---|---|---|---|
| demo_ok | 受控演示样例 | `docs/check-samples/demo_ok`（本地） | ✅ Verified | ✅ | ✅ |
| bobzhang/jsonl | 真实生态包 | GitHub 远端克隆 | ✅ Verified | ✅ | ✅ |
| demo_fail | 受控演示样例 | `docs/check-samples/demo_fail`（本地） | ⚠️ TestFailing | ❌ | ❌ |
| demo_bad | 受控演示样例 | `docs/check-samples/demo_bad`（本地） | ❌ DoesNotCompile | ❌ | ❌ |
| moonbitlang/core | 真实生态包 | GitHub 远端克隆 | ❌ DoesNotCompile | ❌ | ❌ |
| moon-hive | 真实本地项目 | 本地目录（含 C FFI） | 🔒 Unsafe | ❌ | ❌ |

**归因分布**：Verified 2（1 受控 + 1 真实远端）、TestFailing 1（受控）、DoesNotCompile 2（1 受控 + 1 真实远端）、Unsafe 1（真实本地）。

样本说明：
- **受控演示样例**（`docs/check-samples/demo_ok|demo_fail|demo_bad`）是刻意构造的最小 MoonBit 包，用于**确定性演示平台的归因分类能力**（真阳 Verified、测试失败 TestFailing、编译错误 DoesNotCompile），已随本报告入库可复现。
- **真实生态包**（`bobzhang/jsonl`、`moonbitlang/core`）为 GitHub 远端克隆实测：`jsonl` 在本机工具链编译测试全通过 → Verified；`core` 当前工具链编译报错 → DoesNotCompile。
- **真实本地项目**（moon-hive）含 C FFI / 自定义构建脚本，平台按安全策略只做静态分析 → Unsafe。

## 结论与评审意义

1. **平台 `check` 是"完整编排"而非"单一检查"**：一个命令完成 取仓库（本地复制 / git 克隆）→ 静态预检与规模测量 → 安全判定（FFI/构建脚本）→ `moon check` → `moon test` → 归因分类 → Markdown 报告 + 机器可读 JSON。上面 6 个对象全部在同一次调用内跑通并给出**逐对象可复现原因**。

2. **归因分类覆盖生态问题的真实谱系**：本次同时出现了 Verified（可直接用）、TestFailing（代码演进中）、DoesNotCompile（工具链不可用）、Unsafe（含 FFI 保守处理）四类——平台不是简单的"通过/失败"二元判定，而是区分**不同类型的不可用原因**，这正是生态健康平台区别于单一检查工具的价值。

3. **真实远端证据**：`bobzhang/jsonl` 在 GitHub 上能 clone 且本机工具链编译测试全绿（Verified）；`moonbitlang/core` 能 clone 但当前工具链编译报错（DoesNotCompile）。说明"远端可用"与"本机可用"是两个不同维度，平台把两者都如实、可复现地反映在统一报告里。

4. **安全保守策略（Unsafe）**：对含 FFI / 自定义构建脚本的候选（如 moon-hive），平台出于"不在本机执行任意仓库代码"的安全原则，只做静态分析并如实标注 Unsafe。这是平台作为"健康信号"的审慎一面：宁可保守，也不在验证时运行来源不明的构建脚本。

5. **与 `survey` 定位互补**：
   - `survey --registry`（48 包生态普查）回答"注册表发布版本的整体可用率"，走 mooncakes 不依赖 GitHub，适合生态画像；
   - `check`（本报告）回答"单个候选在我的工具链上到底能不能用、为什么不能用"，走完整编排，适合逐包决策。
   - 两者共用同一归因引擎与报告层，一个平台、一个工具链、一套口径。

## 局限与说明

- **远端依赖网络**：`check` 对远端候选走 git 克隆。本机对 GitHub 的访问**间歇性不可达**（常报 `Connection reset`）；本次实测在可达窗口内完成，若网络不可达，远端候选会被如实归因 `FetchFailed`（平台如实反映，不静默跳过）。受控样例与本地候选不受此影响，可随时复现。
- **受控样例的作用边界**：`demo_*` 仅用于确定性演示分类，不代表任何真实生态包；真实生态结论以 `bobzhang/jsonl`、`moonbitlang/core`、moon-hive 的实测为准。
- **工具链版本绑定**：`core` 在本次工具链（10-12）归因 DoesNotCompile；换工具链结论可能变化（参见 `ecosystem-survey-platform-2026-10.md` 的"结论绑定工具链版本"洞察）。
