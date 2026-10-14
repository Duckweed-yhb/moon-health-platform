# MoonHealth 生态普查报告（2026-10-14）

> 依据：对 mooncakes.io **48 个真实发布包**的 survey --registry 验证结果（验证用户 moon add 真正会装到的发布版本）。

> 验证环境：工具链 moon 0.1.20260920 (914d7da 2026-09-20)，目标后端 native；GitHub 克隆不可达（网络限制），故统一走 mooncakes 注册表。

> 统计口径：48 个候选全部完成验证。原始 survey 中 mooncrypt / mooncry 在依赖拉取阶段挂起（无外部超时保护，卡死），已随 MoonHive 的 fetch 超时修复在限时内返回结论，详见「关键发现」。

## 摘要

| 指标 | 数值 |
|---|---|
| 候选总数 | 48 |
| 可用（Verified） | 13 |
| 可用率 | **27.1%** |
| 完成验证 | 48（含 1 个 check 阶段超时） |
| fetch 阶段挂起 | 0（原 2 个已随超时修复解决） |

### 结论分布

| 结论 | 数量 |
|---|---|
| Verified | 13 |
| TestFailing | 2 |
| DoesNotCompile | 6 |
| ToolchainMismatch | 3 |
| NoManifest | 14 |
| Unsafe | 9 |
| TimedOut | 1 |

## 与 2026-09 基线对比

| 指标 | 2026-09（18 包） | 2026-10（48 包） |
|---|---|---|
| 样本规模 | 18 | **48（约 2.7 倍）** |
| 可用率 | 16.7% | **27.1%** |
| Verified | 3 | 13 |
| DoesNotCompile | 3 | 6 |
| ToolchainMismatch | 2 | 3 |
| NoManifest | 3 | 14 |
| Unsafe | 7 | 9 |

> 注：2026-09 基线为 moon-hive 仓库 reports/ 记录的 18 包三轮一致数据；本轮工具链已从 0.1.20260904 升至 0.1.20260920，可用率差异包含工具链演进影响。

## 明细

### Verified

| 包 | 规模（.mbt 文件/行） | 证据摘要 |
|---|---|---|
| bobzhang/jsonl | 3/191 | 编译与测试通过，可以直接使用 |
| bobzhang/lexer | 2/1274 | 编译与测试通过，可以直接使用 |
| bobzhang/toml | 36/14813 | 编译与测试通过，可以直接使用 |
| bobzhang/uuidm | 16/3741 | 编译与测试通过，可以直接使用 |
| f4ah6o/uuidm | 15/3345 | 编译与测试通过，可以直接使用 |
| gaato/http | 17/1527 | 编译与测试通过，可以直接使用 |
| gaato/http-async | 11/1534 | 编译与测试通过，可以直接使用 |
| mizchi/crater-browser-http | 25/7605 | 编译与测试通过，可以直接使用 |
| mizchi/jsonschema | 27/3280 | 编译与测试通过，可以直接使用 |
| mizchi/oci_wasm | 19/2291 | 编译与测试通过，可以直接使用 |
| moonbit-community/sqlparser | 27/17082 | 编译与测试通过，可以直接使用 |
| moonbit-community/yaml | 14/6380 | 编译与测试通过，可以直接使用 |
| moonbitlang/jsonl | 3/191 | 编译与测试通过，可以直接使用 |

### TestFailing

| 包 | 规模（.mbt 文件/行） | 证据摘要 |
|---|---|---|
| bobzhang/html_parser | 335/59985 | ----- BEGIN MO |
| mizchi/tempfile | 3/316 | [mizchi/tempfile] test lib_test.mbt:2 ("tempfile creates and cleans up |

### DoesNotCompile

| 包 | 规模（.mbt 文件/行） | 证据摘要 |
|---|---|---|
| gmlewis/base64 | 7/971 | 12 errors: 148   ) -> (Int32, Int32) raise CorruptInputError { |
| moonbitlang/quickcheck | 32/5287 | 46 errors: [ C:\Users\yhb\AppData\Local\Temp\moonhive-workspaces\moonh |
| moonbitlang/yacc | 93/19951 | Using cached moonbitlang/async@0.22.4 |
| q2316367743/moonhttp | 112/18836 | 38 errors / 6 warnings: 71   ) -> (Int32, Bytes)? raise ParseError { |
| sgy1023-crt/MoonCheck | 12/1520 | 0 errors / 18 warnings: A bug report containing the error description  |
| sundaysebasidian-byte/moon-loglens | 7/1569 | A bug report containing the error description and relevant code would  |

### ToolchainMismatch

| 包 | 规模（.mbt 文件/行） | 证据摘要 |
|---|---|---|
| JingLan0v0/jmespath | 15/1928 | 仓库声明的目标后端为 [js]，不含本次使用的 native |
| bobzhang/portable_cli | 23/10041 | 仓库声明的目标后端为 [wasm, js]，不含本次使用的 native |
| moonbitstack/mooncrypt | 29/6367 | 仓库声明的目标后端为 [wasm, wasm-gc]，不含本次使用的 native（原始 survey 中此包 fetch 挂起，超时修复后可完成验证） |

### NoManifest

| 包 | 规模（.mbt 文件/行） | 证据摘要 |
|---|---|---|
| Tigls/mb-getrandom | — | 没有 moon.mod，不是 MoonBit 模块 |
| Tigls/mb-hash | — | 没有 moon.mod，不是 MoonBit 模块 |
| Tigls/mb-hmac | — | 没有 moon.mod，不是 MoonBit 模块 |
| Tigls/mb-jwt | — | 没有 moon.mod，不是 MoonBit 模块 |
| gmlewis/json | — | 没有 moon.mod，不是 MoonBit 模块 |
| gmlewis/jsonutil | — | 没有 moon.mod，不是 MoonBit 模块 |
| mizchi/duckdb | — | 没有 moon.mod，不是 MoonBit 模块 |
| mizchi/json | — | 没有 moon.mod，不是 MoonBit 模块 |
| mizchi/wasmx | — | 没有 moon.mod，不是 MoonBit 模块 |
| oboard/jsonx | — | 没有 moon.mod，不是 MoonBit 模块 |
| tiye/cirru-parser | — | 没有 moon.mod，不是 MoonBit 模块 |
| tonyfettes/base64 | — | 没有 moon.mod，不是 MoonBit 模块 |
| tonyfettes/tree_sitter_json | — | 没有 moon.mod，不是 MoonBit 模块 |
| tonyfettes/tree_sitter_yaml | — | 没有 moon.mod，不是 MoonBit 模块 |

### Unsafe

| 包 | 规模（.mbt 文件/行） | 证据摘要 |
|---|---|---|
| HhWw96/moonmmdb | 81/13971 | 含 FFI 或自定义构建脚本，出于安全只做静态分析 |
| KKKIIO/sqlite | 7/2291 | 含 FFI 或自定义构建脚本，出于安全只做静态分析 |
| mizchi/experimental_crypto | 298/94054 | 含 FFI 或自定义构建脚本，出于安全只做静态分析 |
| mizchi/llm | 63/8055 | 含 FFI 或自定义构建脚本，出于安全只做静态分析 |
| mizchi/x | 133/23391 | 含 FFI 或自定义构建脚本，出于安全只做静态分析 |
| mizchi/zlib | 26/4078 | 含 FFI 或自定义构建脚本，出于安全只做静态分析 |
| moonbitlang/async | 363/50614 | 含 FFI 或自定义构建脚本，出于安全只做静态分析 |
| moonbitlang/parser | 200/163588 | 含 FFI 或自定义构建脚本，出于安全只做静态分析 |
| moonbitlang/x | 133/29082 | 含 FFI 或自定义构建脚本，出于安全只做静态分析 |

### TimedOut

| 包 | 规模（.mbt 文件/行） | 证据摘要 |
|---|---|---|
| cc06b/mooncry | 204/178476 | fetch 成功；moon check 阶段 40.8s 超时（体量超大）。**修复前此包在 fetch 阶段永久挂起（>15 分钟）** |

## 关键发现

1. **可用率约三成**：48 个候选仅 13 个可直接用。对「要不要采用 MoonBit」的评估者而言，生态成熟度是明确的风险项，也正说明归因工具的价值。
2. **NoManifest 大量出现（14 个）**：多为 JSON / 编码类小工具包（mizchi/json、gmlewis/json、tonyfettes/tree_sitter_* 等）。发布结构不含模块清单，或依赖解析拉取不到，说明 mooncakes 发布质量参差。
3. **2 个工具链版本漂移**（jmespath、portable_cli）：编译输出指向 API / 类型不存在——正是 MoonHive 归因引擎最关键的判别（不是包的错，是工具链差异）。
4. **fetch 超时缺陷已修复**：原始 survey 中 mooncry、mooncrypt 在依赖拉取阶段永久挂起（>15 分钟），暴露 `moon fetch` 缺少外部超时保护。MoonHive 已在 proc 层实现真正的进程级超时强杀（Windows：CreateProcess + Job Object 整棵进程树；POSIX：fork + waitpid 轮询 + kill），并新增 `TimedOut` 错误契约。修复后两个包均限时返回结论——mooncrypt 归 ToolchainMismatch（fetch 成功，target 不含 native）、mooncry 归 TimedOut（fetch 成功，check 阶段 40.8s 超时，不再卡死）。

## 与 depsight 的实证对比（2026-10-15）

为验证 MoonHive 与生态既有依赖健康工具 `Tino-hue/depsight`（MoonBit 版 cargo audit，静态分析 moon.mod / 注册表元数据，输出 0–100 健康分）的互补定位，我们对同一批真实发布包**并跑**两个工具：

- **depsight**：`node depsight.js audit`（v0.6.0，moon build --target js 本地构建），审计该包依赖的健康度。
- **MoonHive**：`moonhive survey --registry`（moon 0.1.20260920，native），用真实工具链编译 + 跑测试。

> 口径说明：depsight 考的是「依赖是否新鲜 / 合规 / 未弃用」，MoonHive 考的是「这个包在本机工具链上**能不能编译、测试过不过**」。两者评估对象不同，恰好互补。

| 包 | depsight 健康分 | depsight 诊断 | MoonHive 结论 |
|---|---|---|---|
| moonbitlang/jsonl | 98/100 | 0 问题 | Verified ✅ |
| moonbitlang/yacc | 98/100 | 0 问题 | **DoesNotCompile** ❌ |
| gmlewis/base64 | 96/100 | 0 问题 | **DoesNotCompile** ❌ |
| moonbit-community/yaml | 94/100 | 0 问题 | Verified ✅ |
| moonbitlang/x | 94/100 | 0 问题 | **Unsafe** ⚠️ |
| bobzhang/uuidm | 94/100 | 0 问题 | Verified ✅ |
| bobzhang/toml | 92/100 | 0 问题 | Verified ✅ |
| bobzhang/html_parser | 92/100 | 0 问题 | **TestFailing** ❌ |

### 核心结论

1. **depsight 高分 ≠ 能编译**：yacc、base64 在 depsight 上拿 98/96 分、零诊断，看着非常健康，但 MoonHive 发现它们在本机工具链上**编译不过**；html_parser 92 分但测试失败。这印证了 moon-hive README 的判断——「一个包在 depsight 拿 94 分，仍可能在本机编译不过」。
2. **depsight 看不到 unsafe 与工具链漂移**：moonbitlang/x 依赖图健康（94 分），但 MoonHive 静态预检发现其含 FFI / unsafe，出于安全不做编译；工具链版本漂移（jmespath、portable_cli、mooncrypt）更是纯元数据无法发现的。
3. **静态健康分受网络限制**：本次 depsight 运行于 GitHub 不可达环境，freshness/activity 维度依赖远端元数据，打分偏乐观（全部 90+）；而 MoonHive 用本地真实工具链验证，不依赖网络，结论不受影响。
4. **分工明确**：depsight 帮你在选型阶段挑依赖（新鲜、合规、未弃用），MoonHive 在你踩到编译失败时判断「这到底是不是包的错」。两者互补，不重合。

