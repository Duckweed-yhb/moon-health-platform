# 贡献指南

感谢你关注 MoonHealth Platform！平台把 [MoonHive](https://github.com/Duckweed-yhb/moon-hive)（生态包归因）与 [MoonProof](https://github.com/Duckweed-yhb/MoonProof)（文档示例验证）编排为统一入口，回答"这个 MoonBit 包能不能用、文档示例有没有失效"。

## 环境

- [MoonBit 工具链](https://www.moonbitlang.com/)（moonc ≥ 0.10.14）
- git

## 构建与测试

```bash
moon build --target native                                   # 构建
moon test --target native                                    # 运行全部测试
moon run --target native cmd/moonhealth -- help              # 运行 CLI
```

## 代码约定

- **分层清晰**：纯计算（可移植、四后端）逻辑放 `features/`（`orchestrate` / `report` / `jsonparse`，不 import 任何 C FFI 包，`supported_targets` 覆盖 wasm+wasm-gc+js+native）；依赖子进程 / 文件系统的 I/O 放 `cmd/moonhealth`（native）。
- **提交信息**遵循 [Conventional Commits](https://www.conventionalcommits.org/zh-hans/)（英文标题 + 中文正文）。
- **新功能必须带测试**；纯计算模块要覆盖四后端。
- 不改动既有公共 API 语义；确需破坏性变更时在 `CHANGELOG.md` 与 `README.md` 同步说明。

## AI 协作约定

本项目使用 AI 辅助开发。请阅读 [docs/AI-USAGE.md](docs/AI-USAGE.md) 了解如何记录与核验 AI 参与，确保"目标、路径与质量由参赛者掌握"。任何 AI 生成的改动都必须通过 `moon build` + `moon test` 真实验证，不以"AI 说可行"代替验证。

## 提交流程

1. fork 并 clone 本仓库。
2. 新建分支，提交改动（遵循上面的提交信息规范）。
3. 本地 `moon build` + `moon test` 全绿。
4. 发起 Pull Request，说明改动动机、影响面与验证方式。
