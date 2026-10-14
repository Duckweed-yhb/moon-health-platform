# 发布流程（RELEASING）

本文档记录 MoonHealth 发布版本的流程。保持流程稳定，是项目可维护性的信号。

## 版本号

遵循 [语义化版本](https://semver.org/lang/zh-CN/)：

- **主版本**：不兼容的 API 变更
- **次版本**：向后兼容的新功能
- **补丁版本**：向后兼容的缺陷修复

## 依赖关系

MoonHealth 依赖底层引擎 **MoonHive**（`Duckweed/moon-hive`，已发布到 mooncakes.io）。发布 MoonHealth 前：

1. 确认所依赖的 MoonHive 版本已在 mooncakes 可 `moon add`（本仓库通过 `moon add Duckweed/moon-hive@<版本>` 锁定）；
2. 若引擎有新版本，先升级依赖并跑通全量测试，再发 MoonHealth。

## 发布步骤

1. **更新版本号**：修改 `moon.mod` 的 `version` 字段。
2. **更新 CHANGELOG.md**：按 Keep a Changelog 风格，把 `[Unreleased]` 改为新版本号，补充发布日期与变更条目。
3. **跑全量验证**：
   ```powershell
   moon test --target native
   ```
   保持全部测试通过、零警告。
4. **提交并打标签**：
   ```powershell
   git add -A
   git commit -m "release: v0.x.y"
   git tag v0.x.y
   git push origin main --tags
   ```
5. **发布到 mooncakes.io**（若本项目作为库被引用）：
   ```powershell
   moon publish
   ```
   （确认 `moon.mod` 的 `readme`、`repository`、`license` 等元数据正确。）

## 发布后

- 在 GitHub Releases 里为标签补一份说明，链接到 CHANGELOG 对应条目；
- 若发布包需要剔除本地探测/构建产物，确认 `.mooncakes` 与 `_build` 未被误打包。

## 回滚

若发布后发现问题：修复后在 `mooncakes.io` 发布新补丁版本（**不要删除或覆盖已发布的版本**，保持发布历史可审计）。
