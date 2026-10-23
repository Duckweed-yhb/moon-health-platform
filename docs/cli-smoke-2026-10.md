# 平台 CLI 退出码契约冒烟验证（2026-10）

用平台自身构建的 `moonhealth` CLI 在真实环境逐条执行，验证文档约定的退出码契约（0/1/10/12/14）**实际生效**。这是平台"技术严谨性"的直接可复现证据——退出码不是写在文档里，而是被命令真实跑出来。

## 验证矩阵

| 命令 | 期望退出码 | 实测退出码 | 说明 |
|---|---|---|---|
| `moonhealth version` | 0 | **0** | 打印版本 |
| `moonhealth help` | 0 | **0** | 打印用法 |
| `moonhealth doctor` | 0 | **0** | 环境检查通过（moon/git/临时目录可用） |
| `moonhealth`（无命令） | 14 | **14** | 参数错误 |
| `moonhealth nosuchcmd` | 14 | **14** | 未知命令 → 参数错误 |
| `moonhealth check demo_ok` | 0 | **0** | 全健康：1 可用 / 0 不健康 |
| `moonhealth check demo_fail` | 1 | **1** | 有失败：归因判定为不健康 |

全部 7 条与约定一致。退出码 10（doctor 环境错误）与 12（隔离工作区创建失败）需构造失败环境才触发，本验证未覆盖（见"说明"）。

## 关键输出摘录（实测）

- `check demo_ok`（健康）→ 退出码 0，报告尾行：
  ```
  **统计**：1 个对象，1 个可用，0 个不健康。
  JSON: [{"subject":"demo_ok","verdict":"Verified","verdict_explain":"编译与测试通过，可以直接使用","verdict_mark":"✅","usable":true,"docs_passed":0,"docs_failed":0,"has_docs":false,"healthy":true}]
  ```
- `check demo_fail`（失败）→ 退出码 1（归因判定不健康）。
- `nosuchcmd` / 无命令 → 退出码 14，同时打印用法。

## 复现命令

在平台仓库根目录（`moon-health-platform/`）执行：

```bash
moon run cmd/moonhealth --target native -- version
moon run cmd/moonhealth --target native -- help
moon run cmd/moonhealth --target native -- doctor
moon run cmd/moonhealth --target native            # 无命令 → 14
moon run cmd/moonhealth --target native -- nosuchcmd   # 未知命令 → 14
moon run cmd/moonhealth --target native -- check docs/check-samples/demo_ok    # → 0
moon run cmd/moonhealth --target native -- check docs/check-samples/demo_fail  # → 1
```

受控样例（`docs/check-samples/demo_ok` / `demo_fail` / `demo_bad`）为平台自带、不依赖外网，可在 CI 或任意环境复现。

## 说明

- `--out-md` / `--out-json` 为 **`survey` 专属**选项（`main.mbt` 命令解析）；`check` 命令不接受这两个选项，传参会被当作候选对象解析（实测会多出 BadInput 对象、退出码转 1），属预期行为而非缺陷。需要落盘时用 `survey`。
- 退出码 10（doctor 环境错误）需在缺 moon/git 或临时目录不可写的环境触发；退出码 12（隔离工作区创建失败）需构造工作区创建失败；本机正常环境不触发，故未在此冒烟覆盖。其语义已在 `cmd/moonhealth/main.mbt` 与 README 退出码表声明。
- 本验证运行于 Windows 本机（含中文路径），native 构建走 MSVC 链接，无 gcc 中文路径问题。
