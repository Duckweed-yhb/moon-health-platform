# 路线图

平台目标是成为 MoonBit 生态的"健康信号"统一入口：一个候选对象能不能用、它的文档示例有没有失效，一条命令给出可复现、可审计的统一报告。当前处于 MVP 之后的第一轮能力补齐。

> 演进原则：平台的核心价值在**编排层自身**（编排、报告、JSON 解析、CLI），能力演进不依赖任一验证工具（moon-hive / MoonProof）的持续维护；归因引擎锁定稳定版本复用，文档验证走子进程边界可替换。详见 README「项目可持续性」。

## 近期（当前迭代）

- [x] `--moonproof` 接入 `--out JSON` 严格解析（文档验证输出真实数字）
- [x] 工程文档：CHANGELOG / CONTRIBUTING / ROADMAP / AI 使用说明
- [x] 生态普查报告：`docs/ecosystem-survey-2026-10.md`（48 包普查 + depsight 对标 + 结论与评审意义）
- [x] 平台自身 `survey` 子命令：复用 moon-hive survey，`--registry` 走 mooncakes（不依赖 GitHub），可输出 Markdown / JSON 报告——平台可自产生态普查
- [x] 平台自身 `check` 批量样例报告（对一批候选用 moonhealth CLI 跑 `check`，沉淀可复现报告：`docs/check-batch-sample-2026-10.md`，含受控样例 `docs/check-samples/`）
- [x] 补测试：编排合并逻辑（`healthy` 判定、`has_docs` 分支）的边界用例（测试 18 → 34）

## 中期

- [ ] 子进程命令中文路径支持：moon-hive `platform/proc` 宽字符分支（参照 fs 0.2.2–0.2.4），使 `--moonproof` 在本机中文路径下可靠
- [ ] 报告多样化：支持更多输出格式 / 更可读的排版
- [ ] 批量模式：一次扫描多个候选，输出汇总报表
- [ ] 增量 / 缓存：避免重复拉取与重复构建

## 远期

- [ ] 接入 mooncakes 元数据，支持"按生态健康度排序选包"
- [ ] 健康分 / Badge（shields.io 式）便于在仓库 README 展示
- [ ] 规则可配置化：阈值、忽略项、自定义判定策略

> 说明：路线图会随生态与评审反馈调整。优先级以开放原子大赛验收标准与用户真实需求为准。
