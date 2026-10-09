# MoonHealth Platform

**MoonBit 生态健康验证平台** —— 把生态包归因（[MoonHive](https://github.com/Duckweed-yhb/moon-hive)）与文档示例验证（[MoonProof](https://github.com/Duckweed-yhb/MoonProof)）编排为统一入口，回答一个核心问题：**这个 MoonBit 包能不能用，它的文档示例有没有失效。**

## 它解决什么问题

MoonBit 生态在快速增长，但开发者在选包、用包、维护包时缺少一个统一的"健康信号"：

- **这个包真的能用吗？** 它可能因为工具链版本不匹配、依赖缺失、编译错误、测试失败、超时等原因而不可用。判断"为什么不能用"需要抓取源码、运行 `moon check/test`、解析编译输出并归因分类——这很繁琐，且极易误判。
- **它的文档示例是新鲜的吗？** MoonBit 版本迭代快，文档里的代码示例会随 API 变化而过期，照抄就跑不起来。

`moonhealth` 把这两个判断编排成一条命令，对每个候选对象输出统一的健康报告（Markdown / JSON）。

## 项目结构

```
moon-health-platform/
├── features/
│   ├── orchestrate/       平台编排层：HealthReport 数据模型 + 合并逻辑（纯计算）
│   └── report/            统一报告渲染：Markdown / JSON / 统计（纯计算，四后端可移植）
├── cmd/
│   └── moonhealth/        CLI 入口：check / doctor / version / help
├── moon.mod               包声明（Duckweed/moon-health-platform）
└── LICENSE                MIT
```

## 安装

需要 [MoonBit 工具链](https://www.moonbitlang.com/)（moonc ≥ 0.10.14）。

```bash
# 直接运行（不需要安装）
moon run Duckweed/moon-health-platform/cmd/moonhealth -- check <候选>
```

或作为依赖引入：

```toml
# moon.mod
import {
  "Duckweed/moon-health-platform",
}
```

## 用法

```
moonhealth <命令> [参数...]

命令:
  check [--moonproof <cmd>] <候选>...   生态健康检查（归因 + 可选文档验证）
  doctor                                  检查平台运行环境（moon / git / 临时目录）
  version                                 打印版本
  help                                    打印本帮助
```

**候选写法**：`owner/repo` | `https://github.com/owner/repo` | 本地目录路径

### 示例

```bash
# 检查一个 GitHub 包
moon run Duckweed/moon-health-platform/cmd/moonhealth -- check moonbit-community/yaml

# 检查本地 MoonBit 项目（含中文路径也支持）
moon run Duckweed/moon-health-platform/cmd/moonhealth -- check "E:\我的项目\my-pkg"

# 同时做文档示例验证（注入 MoonProof 命令）
moon run Duckweed/moon-health-platform/cmd/moonhealth -- check ./local-pkg --moonproof "moon run --target native C:/path/MoonProof/cmd/moonproof --"

# 检查运行环境
moon run Duckweed/moon-health-platform/cmd/moonhealth -- doctor
```

### 输出

`check` 对每个候选打印一行人类可读结论，最后输出 Markdown + JSON 汇总：

```text
✅ moonbit-community/yaml  →  Verified
    编译与测试全绿，可直接使用
    包可用性: 可用
    文档验证: 无文档需要验证
    整体健康: ✅ 健康

===== 平台健康报告 =====
# MoonHealth 生态健康报告

| 对象 | 归因 | 可用 | 文档 | 健康 |
|---|---|---|---|---|
| moonbit-community/yaml | ✅ Verified | ✅ | — | ✅ |

**统计**：1 个对象，1 个可用，0 个不健康。

JSON: [{"subject":"moonbit-community/yaml","verdict":"Verified",...}]
```

### 退出码

| 码 | 含义 |
|---|---|
| 0 | 全部健康 / 无失败 |
| 1 | 有失败（包不可用 / 文档失效） |
| 2 | 运行错误 / 参数错误 |
| 10 | 环境错误 |
| 14 | 参数错误 |

## 归因引擎（复用 MoonHive）

平台复用 [MoonHive](https://github.com/Duckweed-yhb/moon-hive) 的 `verify/diagnose` 归因引擎，对编译输出做九类分类：

- `Verified` 编译与测试全绿
- `TestFailing` 编译通过但测试失败
- `DoesNotCompile` 真编译错误
- `ToolchainMismatch` 工具链版本/API 不匹配
- `MissingDependency` 依赖缺失
- `NoManifest` 无 moon.mod 清单
- `TimedOut` 超时
- `Unsafe` 含 FFI（按配置判为不可直接使用）
- `FetchFailed` 拉取源码失败

判定顺序有讲究：先排前提（无清单 → NoManifest），再安全（含 FFI → Unsafe），再超时，再后端声明不匹配，再 check 失败（区分依赖缺失/工具链不匹配/真编译错误），最后才看 test。顺序错了会误判。

## 文档验证（可选接入 MoonProof）

`--moonproof <cmd>` 让平台通过子进程调用 [MoonProof](https://github.com/Duckweed-yhb/MoonProof) 验证候选仓库的文档代码示例是否仍可编译。当前版本对 MoonProof 输出的块数做保守解析（尚未接入 `--out JSON` 严格解析），报告如实标注"无文档验证数据"，不夸大能力。

## 开发

```bash
moon build --target native        # 构建
moon test --target native         # 运行测试（当前 10 个）
```

持续集成见 `.github/workflows/`，覆盖检查、构建、测试流程。

## 许可证

[MIT](./LICENSE) · © Duckweed-yhb

## 相关项目

- [MoonHive](https://github.com/Duckweed-yhb/moon-hive) — MoonBit 工具链输出的诊断归因库
- [MoonProof](https://github.com/Duckweed-yhb/MoonProof) — MoonBit 文档代码示例失效验证工具
