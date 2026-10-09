///|
/// features/orchestrate — 平台编排层
///
/// 把 MoonHive（生态包归因，库方式 import）与 MoonProof（文档验证，子进程调用）
/// 编排为一个统一的「生态健康检查」流程，产出统一的健康报告。
///
/// 设计约束：
///   - moon-hive 的 verify/diagnose 是纯计算库，直接 import 复用归因引擎；
///   - moon-proof 是 native + C FFI 的 CLI 工具，平台通过子进程调用它做文档验证，
///     避免把它的 C FFI 依赖图拖进平台模块。
///
/// 语义：
///   moonhealth check <owner/repo>           检查一个包的生态健康（归因 + 可选文档验证）
///   moonhealth inspect <owner/repo>         只做包归因（调 moon-hive inspect）
///   moonhealth docs <dir>                   只做文档验证（调 moon-proof）
///   moonhealth survey <候选>...             生态普查（调 moon-hive survey）
///   moonhealth doctor                       检查平台运行环境（moon/git/临时目录）
///   moonhealth version                      打印版本
///
/// 退出码约定（与子工具对齐）：
///   0  成功（全部健康 / 无失败）
///   1  有失败（包不可用 / 文档失效）
///   2  运行错误 / 参数错误
///   10 环境错误   11 进程错误   12 文件错误   13 未找到   14 参数错误   15 工具链错误

///|
/// 平台的统一健康结论：对一个检查对象，归因引擎 + 文档验证的合并结果。
pub struct HealthReport {
  /// 检查对象描述（owner/repo 或目录）
  subject : String
  /// 归因引擎结论的短标签（如 Verified / ToolchainMismatch）
  verdict : String
  /// 归因结论的中文说明
  verdict_explain : String
  /// 归因结论的符号（✅ ⚠️ ❌ 🚫 ⏱️ ...）
  verdict_mark : String
  /// 包是否可用（归因层）
  usable : Bool
  /// 文档验证：通过块数 / 失败块数
  docs_passed : Int
  docs_failed : Int
  /// 是否有文档需要验证（该对象不是纯库包时可能为 false）
  has_docs : Bool
  /// 合并后的整体是否健康（包可用 且 文档无失效）
  healthy : Bool
}

///|
/// 构造一个合并的健康报告。healthy = usable && (!has_docs || docs_failed == 0)。
pub fn make_health_report(
  subject : String,
  verdict : String,
  verdict_explain : String,
  verdict_mark : String,
  usable : Bool,
  docs_passed : Int,
  docs_failed : Int,
  has_docs : Bool
) -> HealthReport {
  let healthy = usable && (if has_docs { docs_failed == 0 } else { true })
  {
    subject,
    verdict,
    verdict_explain,
    verdict_mark,
    usable,
    docs_passed,
    docs_failed,
    has_docs,
    healthy,
  }
}

///|
/// 渲染健康报告为人类可读文本。
pub fn render_health(r : HealthReport) -> String {
  let mut s = r.verdict_mark + " " + r.subject + "  →  " + r.verdict + "\n"
  s = s + "    " + r.verdict_explain + "\n"
  s = s + "    包可用性: " + (if r.usable { "可用" } else { "不可用" }) + "\n"
  s = s + "    文档验证: " + (if r.has_docs {
    r.docs_passed.to_string() + " 通过 / " + r.docs_failed.to_string() + " 失败"
  } else {
    "无文档需要验证"
  }) + "\n"
  s = s + "    整体健康: " + (if r.healthy { "✅ 健康" } else { "❌ 不健康" })
  s
}

///|
/// 渲染为一行 JSON（便于脚本消费）。
pub fn to_json(r : HealthReport) -> String {  let mut s = "{"
  s = s + "\"subject\":\"" + escape(r.subject) + "\""
  s = s + ",\"verdict\":\"" + r.verdict + "\""
  s = s + ",\"verdict_explain\":\"" + escape(r.verdict_explain) + "\""
  s = s + ",\"verdict_mark\":\"" + r.verdict_mark + "\""
  s = s + ",\"usable\":" + (if r.usable { "true" } else { "false" })
  s = s + ",\"docs_passed\":" + r.docs_passed.to_string()
  s = s + ",\"docs_failed\":" + r.docs_failed.to_string()
  s = s + ",\"has_docs\":" + (if r.has_docs { "true" } else { "false" })
  s = s + ",\"healthy\":" + (if r.healthy { "true" } else { "false" })
  s + "}"
}

///|
/// JSON 字符串转义（最小实现：引号与反斜杠）。
fn escape(s : String) -> String {
  let mut out = ""
  for c in s {
    if c == '"' {
      out = out + "\\\""
    } else if c == '\\' {
      out = out + "\\\\"
    } else {
      out = out + c.to_string()
    }
  }
  out
}

// ---------- 单元测试 ----------

test "健康报告：可用 + 文档全过 → 健康" {
  let r = make_health_report(
    "owner/pkg",
    "Verified",
    "编译与测试全绿，可直接使用",
    "✅",
    true,
    5,
    0,
    true,
  )
  assert_true(r.healthy)
  assert_eq(r.docs_passed, 5)
  assert_eq(r.docs_failed, 0)
}

test "健康报告：可用但文档有失效 → 不健康" {
  let r = make_health_report("owner/pkg", "Verified", "", "✅", true, 3, 1, true)
  assert_false(r.healthy)
}

test "健康报告：包不可用 → 不健康（无论文档）" {
  let r = make_health_report(
    "owner/pkg",
    "ToolchainMismatch",
    "版本/API 不兼容",
    "🚫",
    false,
    0,
    0,
    false,
  )
  assert_false(r.healthy)
  assert_false(r.has_docs)
}

test "健康报告：无文档时只看包可用性" {
  let r = make_health_report("owner/pkg", "Verified", "", "✅", true, 0, 0, false)
  assert_true(r.healthy)
}

test "to_json 输出合法字段" {
  let r = make_health_report("a/b", "Verified", "ok", "✅", true, 2, 0, true)
  let j = to_json(r)
  assert_true(j.contains("\"subject\":\"a/b\""))
  assert_true(j.contains("\"healthy\":true"))
}

test "escape 处理引号与反斜杠" {
  assert_eq(escape("a\"b"), "a\\\"b")
  assert_eq(escape("c\\d"), "c\\\\d")
}
