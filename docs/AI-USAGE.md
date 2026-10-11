# AI 使用说明

本项目使用 AI 编程工具辅助开发。依据赛事"AI 可解释"要求，这里如实记录 AI 参与的范围、边界与核验方式——**目标、路径与质量始终由参赛者掌握，AI 不替参赛者做技术判断。**

## AI 参与的范围

- **代码生成与接口设计**：AI 协助编写 MoonBit 代码（如 `features/jsonparse` 解析器、CLI 参数解析、报告渲染）。
- **测试补全**：AI 根据核心路径生成 / 补充测试用例。
- **文档撰写**：AI 协助起草 README / CHANGELOG / 工程文档。
- **工程脚手架**：AI 辅助搭建包结构、CI 配置。

## AI 不参与的边界

- **技术选型与架构决策**：包边界（纯计算 vs native）、四后端可移植性、归因判定顺序、JSON 契约等，由参赛者依据对 MoonBit 生态与项目的理解决定。
- **质量验收**：每个 AI 生成的功能都必须通过 `moon build` + `moon test` 真实验证，并在端到端（真实包 / 真实 MoonProof 调用）下确认结果，不以"AI 说可行"代替验证。
- **开源合规**：许可证、依赖来源、是否参考他人实现，由参赛者核验。

## 如何核验 AI 产出

1. **构建**：`moon build --target native` 0 错误。
2. **测试**：`moon test --target native` 全绿。
3. **端到端**：对含 `moonbit` 代码块的纯包跑 `check --moonproof`，确认"文档验证：X 通过 / Y 失败"为真实数字而非占位。
4. **复现**：任意第三方 clone 后按 README 步骤可复现 build / test / 运行。

## 记录方式

AI 参与的具体改动在提交信息（Conventional Commits）与 `CHANGELOG.md` 中体现；本文件说明整体机制，不在每个 commit 重复声明。
