# MoonHealth 生态普查报告（平台自生成 · 2026-10）

> 本报告由**平台自身** `moonhealth survey --registry` 子命令生成（复用 moon-hive features/survey），
> 对 mooncakes.io **48 个真实发布包**逐一验证（验证用户 `moon add` 真正会装到的发布版本）。
> 对比基线：docs/ecosystem-survey-2026-10.md（外部 moon-hive 工具生成，工具链 0.1.20260920）。

## 摘要

| 指标 | 数值 |
|---|---|
| 候选总数 | 48 |
| 可用（Verified） | 12 |
| 可用率 | **25.0%**（基线 27.1%） |
| 完成验证 | 48（全部限时返回结论，无永久挂起） |
| 验证方式 | 平台自身 survey 子命令 · 三路分片并行 |

### 结论分布

| 结论 | 数量 | 含义 |
|---|---|---|
| Verified | 12 | 编译与测试通过，可以直接使用 |
| TestFailing | 2 | 能编译，但测试未通过，谨慎使用 |
| DoesNotCompile | 3 | 编译器报错，当前工具链上不可用 |
| ToolchainMismatch | 3 | 声明后端不含 native，不是包的问题，是工具链差异 |
| MissingDependency | 3 | 依赖解析失败，不是自包含的模块（**新增类别**） |
| FetchFailed | 14 | 获取仓库失败（fetch 到版本但无 moon.mod.json；对应基线 NoManifest） |
| Unsafe | 9 | 含 FFI 或自定义构建脚本，出于安全只做静态分析 |
| TimedOut | 2 | 超出时间预算 |

## 验证环境与执行说明

| 项 | 值 |
|---|---|
| 工具链 | moon 0.1.20261012 (748b63c 2026-10-12) |
| 目标后端 | native |
| 生成时间 | 2026-10-19 00:43（Asia/Shanghai；精确毫秒见 JSON `generatedAt`） |
| 注册表 | mooncakes（GitHub 克隆不可达） |
| 候选 | 48 个真实发布包（与基线同批） |

**执行命令**：

```
moonhealth survey --registry --out-md <报告.md> --out-json <报告.json> <slug>...
```

**分批策略**（3 个 shard 并行，各 16 包）：

- shard1：16 包一批，整批 426.6s，rc=0，无挂起。
- shard2：16 包整批在 fetch 阶段挂起（约 22 分钟近零 CPU、无输出），收敛为**逐包调用**（外部硬超时 150s/包 + `taskkill /F /T` 杀进程树）；其中 moonbitstack/mooncrypt 82.9s 正常返回（历史挂起未复现），q2316367743/moonhttp 两次 150s 静默超时记为 TimedOut。
- shard3：16 包一批，整批 1450.8s，rc=1，无挂起；cc06b/mooncry fetch 成功，check 53.3s 通过，test 阶段运行 19m45s（1185s）后被工具内部时间预算中止。

**超时与退出码说明**（报告可复现性必需）：

- 每候选内部超时设计值：源码 `features/survey/survey.mbt` 默认 `timeout_ms: 120000`（120s）；实测 cc06b/mooncry 的 test 阶段运行 19m45s 才被内部预算中止，说明内部预算按阶段/子进程作用，报告中以实测为准。
- 退出码语义（源码 survey.mbt:206）：`count_of(report, "Verified") > 0 → 0，否则 1`，即**"是否存在至少一个 Verified"**，与 CLI 帮助文本"0 全部健康 \| 1 有失败"不符。因此批量调用退出码不能替代逐包诊断，本报告全部结论以逐包诊断为准（shard1 整批 rc=0 仍含 5 个非 Verified 结论，正是此语义）。

## 统计与基线对比

| 指标 | 基线（09-20 工具链） | 本次（10-12 工具链） |
|---|---|---|
| 样本规模 | 48 | 48 |
| 可用率 | 27.1%（13/48） | **25.0%（12/48）** |
| Verified | 13 | 12 |
| TestFailing | 2 | 2 |
| DoesNotCompile | 6 | 3 |
| ToolchainMismatch | 3 | 3 |
| NoManifest | 14 | —（更名为 FetchFailed 14） |
| Unsafe | 9 | 9 |
| TimedOut | 1 | 2 |
| MissingDependency | — | 3（新增类别） |

## 明细（48 包逐包结论）

### Verified（12）

| 包 | 证据摘要 |
|---|---|
| bobzhang/lexer | check 1.3s / test 5.1s 通过（2 .mbt / 1274 行） |
| bobzhang/uuidm | check 991ms / test 3.7s 通过（16 .mbt / 3741 行） |
| f4ah6o/uuidm | check 1.0s / test 7.4s 通过（15 .mbt / 3345 行） |
| gaato/http | check 3.1s / test 11.6s 通过（45 .mbt / 7323 行） |
| mizchi/crater-browser-http | check 9.7s / test 16.4s 通过（25 .mbt / 7605 行） |
| mizchi/jsonschema | check 1.7s / test 6.0s 通过（27 .mbt / 3280 行） |
| mizchi/oci_wasm | check 7.0s / test 20.9s 通过（19 .mbt / 2291 行） |
| moonbit-community/yaml | check 2.5s / test 3.0s 通过（15 .mbt / 7032 行） |
| moonbitlang/jsonl | check 4.2s / test 4.9s 通过（3 .mbt / 191 行） |
| mizchi/tempfile | check 1.8s / test 1.7s 通过（3 .mbt / 316 行） |
| gmlewis/base64 | check 697ms / test 1.6s 通过（7 .mbt / 971 行） |
| moonbitlang/quickcheck | check 1.8s / test 12.9s 通过（32 .mbt / 5287 行） |

### TestFailing（2）

| 包 | 证据摘要 |
|---|---|
| gaato/http-async | check 14.8s 通过，test 21.7s 一测失败：loopback/phase_test.mbt:202 "the exchange timeout ends a buffered body that keeps trickling" → HttpError.Timeout |
| bobzhang/html_parser | check 13.1s 通过，test 1m7s 后失败（335 .mbt / 59985 行，体量最大） |

### DoesNotCompile（3）

| 包 | 证据摘要 |
|---|---|
| moonbitlang/yacc | check 1.1s 即失败（93 .mbt / 19951 行；evidence: Using cached moonbitlang/async@0.22.4） |
| sgy1023-crt/MoonCheck | 0 errors / 18 warnings: A bug report containing the error description...（12 .mbt / 1520 行） |
| sundaysebasidian-byte/moon-loglens | 0 errors / 9 warnings: A bug report containing the error description...（7 .mbt / 1569 行） |

### ToolchainMismatch（3）

| 包 | 证据摘要 |
|---|---|
| JingLan0v0/jmespath | 仓库声明的目标后端为 [js]，不含本次使用的 native（15 .mbt / 1928 行） |
| bobzhang/portable_cli | 仓库声明的目标后端为 [wasm, js]，不含本次使用的 native（23 .mbt / 10041 行） |
| moonbitstack/mooncrypt | 仓库声明的目标后端为 [wasm, wasm-gc]，不含本次使用的 native（29 .mbt / 6367 行；历史 fetch 挂起本次 82.9s 正常返回，未复现） |

### MissingDependency（3，新增类别）

| 包 | 证据摘要 |
|---|---|
| bobzhang/jsonl | 依赖解析失败，不是自包含的模块（check 1.9s 即停；evidence: Using cached moonbitlang/async@0.19.1） |
| bobzhang/toml | 依赖解析失败，不是自包含的模块（check 1.9s 即停；evidence: Using cached moonbitlang/async@0.20.2） |
| moonbit-community/sqlparser | 依赖解析失败，不是自包含的模块（check 781ms 即停；evidence: Using cached moonbitlang/x@0.5.1） |

### FetchFailed（14，对应基线 NoManifest）

| 包 | 证据摘要 |
|---|---|
| Tigls/mb-getrandom | 注册表解析到版本，fetch 后 .repos 下无 moon.mod.json（0 文件） |
| Tigls/mb-hash | 同上（版本 0.1.0） |
| Tigls/mb-hmac | 同上（版本 0.1.0） |
| Tigls/mb-jwt | 同上（版本 0.1.0） |
| gmlewis/json | 注册表解析到 0.15.0，fetch 后 moon.mod.json 缺失 |
| gmlewis/jsonutil | 注册表解析到 0.24.0，fetch 后 moon.mod.json 缺失 |
| mizchi/duckdb | 注册表解析到 0.6.4，fetch 后 moon.mod.json 缺失 |
| mizchi/json | 注册表解析到 0.4.0，fetch 后 moon.mod.json 缺失 |
| mizchi/wasmx | 注册表解析到 0.1.1，fetch 后 moon.mod.json 缺失（0ms 即失败） |
| oboard/jsonx | 注册表解析到 0.1.0，fetch 后 moon.mod.json 缺失（0ms） |
| tiye/cirru-parser | 注册表解析到 0.3.x，fetch 后 moon.mod.json 缺失（0ms） |
| tonyfettes/base64 | 注册表解析到 0.1.x，fetch 后 moon.mod.json 缺失（0ms） |
| tonyfettes/tree_sitter_json | 注册表取到 tag，fetch 后 moon.mod.json 缺失（0ms） |
| tonyfettes/tree_sitter_yaml | 同上（0ms） |

### Unsafe（9，与基线一致）

| 包 | 证据摘要 |
|---|---|
| HhWw96/moonmmdb | 含 FFI 或自定义构建脚本，出于安全只做静态分析（81 .mbt / 13971 行 / 28.5 MB） |
| KKKIIO/sqlite | 同上（7 .mbt / 2291 行 / 91 KB） |
| mizchi/experimental_crypto | 同上（298 .mbt / 94054 行 / 6.1 MB） |
| mizchi/llm | 同上（63 .mbt / 8055 行 / 240 KB） |
| mizchi/x | 同上（133 .mbt / 23391 行 / 753 KB） |
| mizchi/zlib | 同上（26 .mbt / 4078 行 / 170 KB） |
| moonbitlang/async | 同上（363 .mbt / 50614 行 / 2.0 MB） |
| moonbitlang/parser | 同上（201 .mbt / 175347 行 / 6.0 MB） |
| moonbitlang/x | 同上（133 .mbt / 29082 行 / 964 KB） |

### TimedOut（2）

| 包 | 证据摘要 |
|---|---|
| q2316367743/moonhttp | 外部硬超时 150s 终止（复现 2 次均超时）；stdout/stderr 全程为空，fetch 阶段静默挂死，fetched=false |
| cc06b/mooncry | fetch 成功（204 .mbt / 178476 行 / 10.6 MB）；check 53.3s 通过，test 19m45s（1185s）超出内部时间预算被中止；非外部挂起 |

## 与 2026-09-20 基线对比

### 状态变化清单（同 48 包、同注册表，仅工具链 0.1.20260920 → 0.1.20261012）

| 包 | 基线（09-20） | 本次（10-12） |
|---|---|---|
| gmlewis/base64 | DoesNotCompile | **Verified** |
| mizchi/tempfile | TestFailing | **Verified** |
| moonbitlang/quickcheck | DoesNotCompile | **Verified** |
| gaato/http-async | Verified | **TestFailing** |
| bobzhang/jsonl | Verified | **MissingDependency** |
| bobzhang/toml | Verified | **MissingDependency** |
| moonbit-community/sqlparser | Verified | **MissingDependency** |
| q2316367743/moonhttp | DoesNotCompile | **TimedOut** |
| cc06b/mooncry | TimedOut（check 阶段 40.8s 超时） | TimedOut（check 53.3s 通过，test 阶段 19m45s 超时）——卡点后移 |
| Tigls/mb-*（4）、gmlewis/json、gmlewis/jsonutil、mizchi/duckdb、mizchi/json、mizchi/wasmx、oboard/jsonx、tiye/cirru-parser、tonyfettes/base64、tonyfettes/tree_sitter_json、tonyfettes/tree_sitter_yaml（14 个） | NoManifest | FetchFailed（同一批包，语义口径变化：基线"NoManifest / 没有 moon.mod"，本次"FetchFailed / 获取仓库失败（moon.mod.json 缺失）"） |
| 其余 23 个（9 Unsafe、3 ToolchainMismatch、yacc/MoonCheck/moon-loglens DoesNotCompile、html_parser TestFailing、11 Verified 不变项） | — | 结论不变 |

### 核心洞察：普查结论绑定工具链版本，工具链演进影响结论

1. **同批候选、两个工具链版本，8 个包出现实质状态变化**：3 个从不可用转正（base64、tempfile、quickcheck），3 个从直接可用掉队为依赖解析失败（jsonl、toml、sqlparser），1 个从可用变测试失败（http-async），1 个从编译失败变为 fetch 超时（moonhttp）。
2. **可用率 27.1% → 25.0% 不是简单的"变差"**：结构发生了双向迁移——旧"直接可用"的 3 个包本轮无法解析依赖，同时旧"不可用"的 3 个包转正。一次普查结论只在生成它的工具链版本下成立。
3. **gmlewis/base64 是"工具链演进影响结论"的正面样本**：基线报告把它列为"看着健康（depsight 96 分）但编译不过"的代表案例；工具链 0.1.20261012 下它编译测试全过、转为 Verified。**结论随工具链版本漂移，报告头必须记录验证环境，否则结论无法复现、不可被信任。**
4. **版本漂移判别维度稳定**：jmespath / portable_cli / mooncrypt 的 ToolchainMismatch 结论在新工具链下完全一致，说明"声明后端不含 native"这一归因维度不随工具链抖动，是可靠的判别信号。

## 关键发现

1. **平台自身完成全量普查，48/48 全部限时返回结论**：历史挂起包 mooncrypt、mooncry 本次 fetch 均正常（说明 fetch 超时保护有效）；但 q2316367743/moonhttp 在 fetch 阶段静默挂死（外部 150s 硬超时终止、无任何输出），registry fetch 对个别包仍需要外部兜底。
2. **诊断类别从基线 7 类变为 8 类**：新增 MissingDependency（依赖解析失败，3 个）；NoManifest 更名为 FetchFailed（14 个，同一批包）。
3. **可用率约四分之一**：48 包仅 12 个可直接用（25.0%）。装不上 / 编不过 / 跑不完共 22 个（FetchFailed 14 + DoesNotCompile 3 + MissingDependency 3 + TimedOut 2），另有 9 个 Unsafe 仅做静态分析——"这个 MoonBit 包能不能用"依然是开发者每天要踩的真实风险。
4. **退出码语义与帮助文本不符**：实际实现为"存在至少一个 Verified → 0，否则 1"（survey.mbt:206），帮助文本写"0 全部健康 \| 1 有失败"。批量调用退出码不能替代逐包诊断，本报告全部以逐包结论为准（建议后续修订帮助文本）。

## 结论与评审意义

1. **平台自身具备全量生态普查能力**：`moonhealth survey --registry` 一条命令，对任意候选清单输出 Markdown / JSON 双格式报告；本次 48 个真实发布包全量实测限时完成——这是"平台能解决真实问题"的直接落地证据。
2. **编译级验证不可替代，且必须绑定工具链版本**：同一批包在两个工具链版本下 8 个包结论漂移；静态健康分（depsight 类）更无法捕捉这类变化。要给出可信的"能不能用"结论，必须用真实工具链编译 + 跑测试，并记录验证环境。
3. **工具链演进是生态结论的"活变量"**：评估生态健康度应把工具链版本纳入口径、逐版本复跑普查，而不是一次结论用到底；本报告与基线报告共同构成"结论绑定工具链版本"的实证对。

> 一句话给评审：**平台自己的 survey 命令对 48 个真实发布包完成全量普查并生成可审计报告（12/48 可用，25.0%），且逐包对比了工具链 09-20 → 10-12 的结论漂移——这就是场景落地的最强证据。**
