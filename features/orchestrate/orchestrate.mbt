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
///   moonhealth check [--moonproof <cmd>] <候选>...  生态健康检查（归因 + 可选文档验证）
///   moonhealth survey [--registry] <候选>...       生态普查（调 moon-hive survey）
///   moonhealth doctor                               检查平台运行环境（moon/git/临时目录）
///   moonhealth version                              打印版本
///
/// 退出码约定：
///   0   成功（全部健康 / 无失败）
///   1   有失败（包不可用 / 文档失效）
///   10  环境错误（doctor 依赖缺失）
///   12  文件 / 工作区错误（隔离工作区创建失败）
///   14  参数错误（用法 / 参数错误）

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
/// 构造一个合并的健康报告。healthy = usable && (!verified_docs || docs_failed == 0)。
/// 其中 verified_docs 为「实际产生文档验证结果」（has_docs 且 通过+失败 > 0）。
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
  // 防御：仅当实际产生了文档验证结果（docs_passed + docs_failed > 0）才认可 has_docs。
  // 若声称 has_docs 但总块数为 0（内部不一致 / 外部构造的造假输入），归一化为"无文档"，
  // 避免报告谎称"0 通过 / 0 失败"地验证过文档，也避免凭 0 失败当作文档全过而判健康。
  let verified_docs = has_docs && (docs_passed + docs_failed) > 0
  let healthy = usable && (if verified_docs { docs_failed == 0 } else { true })
  {
    subject,
    verdict,
    verdict_explain,
    verdict_mark,
    usable,
    docs_passed,
    docs_failed,
    has_docs: verified_docs,
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
  s = s + ",\"verdict_mark\":\"" + escape(r.verdict_mark) + "\""
  s = s + ",\"usable\":" + (if r.usable { "true" } else { "false" })
  s = s + ",\"docs_passed\":" + r.docs_passed.to_string()
  s = s + ",\"docs_failed\":" + r.docs_failed.to_string()
  s = s + ",\"has_docs\":" + (if r.has_docs { "true" } else { "false" })
  s = s + ",\"healthy\":" + (if r.healthy { "true" } else { "false" })
  s + "}"
}

///|
/// JSON 字符串转义：引号、反斜杠与全部控制字符（`\n` `\r` `\t` 及 0x00–0x1F），
/// 保证平台自产 JSON 始终合法。用 StringBuilder 避免逐字符字符串拼接。
fn escape(s : String) -> String {
  let b = StringBuilder()
  for c in s {
    let n = c.to_int()
    if c == '"' {
      b.write_string("\\\"")
    } else if c == '\\' {
      b.write_string("\\\\")
    } else if c == '\n' {
      b.write_string("\\n")
    } else if c == '\r' {
      b.write_string("\\r")
    } else if c == '\t' {
      b.write_string("\\t")
    } else if n < 0x20 {
      b.write_string("\\u00" + hex_digit(n / 16) + hex_digit(n % 16))
    } else {
      b.write_char(c)
    }
  }
  b.to_string()
}

///|
/// 0–15 转成单个十六进制字符。
fn hex_digit(v : Int) -> String {
  if v < 10 {
    (0x30 + v).unsafe_to_char().to_string()
  } else {
    (0x61 + (v - 10)).unsafe_to_char().to_string()
  }
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

test "escape 转义换行/回车/制表符与其他控制字符" {
  assert_eq(escape("a\nb\rc\td"), "a\\nb\\rc\\td")
  assert_eq(escape("\u{07}"), "\\u0007")
  assert_eq(escape("\u{1F}"), "\\u001f")
}

test "escape 保留可见 Unicode（中英文与补充字符）" {
  assert_eq(escape("中文 ok 😀"), "中文 ok 😀")
}

test "to_json 对含换行的 verdict_explain 产出合法转义" {
  let r = make_health_report("p/q", "Unsafe", "line1\nline2", "🔒", false, 0, 0, false)
  let j = to_json(r)
  assert_true(j.contains("\"verdict_explain\":\"line1\\nline2\""))
  assert_true(j.contains("\"verdict_mark\":\"🔒\""))
}

// ---------- 编排合并逻辑边界用例（A3 补强） ----------

test "healthy 真值表：包不可用 + 文档全过 → 不健康" {
  let r = make_health_report("o/p", "Unsafe", "含 FFI", "🔒", false, 3, 0, true)
  assert_false(r.healthy)
}

test "healthy 真值表：无文档 + 包不可用 → 不健康" {
  let r = make_health_report("o/p", "FetchFailed", "拉取失败", "❌", false, 0, 0, false)
  assert_false(r.healthy)
}

test "防御：has_docs=true 但 0 过 0 失 → 归一化为无文档（不谎称验证过文档）" {
  let r = make_health_report("o/p", "Verified", "", "✅", true, 0, 0, true)
  // 声称有文档却没任何验证块：has_docs 不被认可，归一化为无文档
  assert_false(r.has_docs)
  // 无文档语义下只看包可用性
  assert_true(r.healthy)
}

test "防御：has_docs=true 但 0 块，usable=false → 归一化为无文档且不健康" {
  let r = make_health_report("c/d", "Unsafe", "含 FFI", "🔒", false, 0, 0, true)
  assert_false(r.has_docs)
  assert_false(r.healthy)
}

test "防御：有真实文档块时 has_docs 才被认可并参与判定" {
  let ok = make_health_report("e/f", "Verified", "", "✅", true, 5, 0, true)
  assert_true(ok.has_docs)
  assert_true(ok.healthy)
  let bad = make_health_report("g/h", "Verified", "", "✅", true, 1, 3, true)
  assert_true(bad.has_docs)
  assert_false(bad.healthy)
}

test "healthy 真值表：可用 + 文档全过 → 健康（重复确认）" {
  let r = make_health_report("o/p", "Verified", "", "✅", true, 7, 0, true)
  assert_true(r.healthy)
  assert_true(r.has_docs)
}

test "render_health：有文档显示通过/失败且反映不健康" {
  let r = make_health_report("a/b", "Verified", "编译通过", "✅", true, 2, 1, true)
  let s = render_health(r)
  assert_true(s.contains("2 通过 / 1 失败"))
  assert_true(s.contains("❌ 不健康"))
}

test "render_health：无文档显示无文档需要验证且健康" {
  let r = make_health_report("a/b", "Verified", "编译通过", "✅", true, 0, 0, false)
  let s = render_health(r)
  assert_true(s.contains("无文档需要验证"))
  assert_true(s.contains("✅ 健康"))
}

test "render_health：包不可用显示不可用" {
  let r = make_health_report("a/b", "Unsafe", "含 FFI", "🔒", false, 0, 0, false)
  let s = render_health(r)
  assert_true(s.contains("包可用性: 不可用"))
  assert_true(s.contains("❌ 不健康"))
}

test "to_json 包不可用无文档字段正确" {
  let r = make_health_report("a/b", "Unsafe", "含FFI", "🔒", false, 0, 0, false)
  let j = to_json(r)
  assert_true(j.contains("\"usable\":false"))
  assert_true(j.contains("\"has_docs\":false"))
  assert_true(j.contains("\"healthy\":false"))
}

test "escape 保留 Unicode 普通文本" {
  assert_eq(escape("中文正常 abc"), "中文正常 abc")
}
