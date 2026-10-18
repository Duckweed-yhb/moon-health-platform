///|
/// features/report — 平台的统一报告渲染层（纯计算，可移植）
///
/// 把多份 HealthReport（包归因 + 文档验证的合并结果）聚合成三种格式：
///   - Markdown（人类可读，默认）
///   - JSON 数组（脚本消费 / 生态普查）
///   - 简单汇总统计（通过/失败/不健康数量）
///
/// 本层不 import 任何 C FFI 包，声明覆盖全部四个后端，作为平台可移植核心的一部分。

///|
/// 一批健康报告的整体统计。
pub struct HealthSummary {
  total : Int
  usable : Int
  unhealthy : Int
  docs_failed_total : Int
}

///|
/// 由一批报告计算统计。
pub fn summarize(reports : Array[@orchestrate.HealthReport]) -> HealthSummary {
  let mut total = 0
  let mut usable = 0
  let mut unhealthy = 0
  let mut docs_failed_total = 0
  for r in reports {
    total = total + 1
    if r.usable {
      usable = usable + 1
    }
    if !r.healthy {
      unhealthy = unhealthy + 1
    }
    docs_failed_total = docs_failed_total + r.docs_failed
  }
  { total, usable, unhealthy, docs_failed_total }
}

///|
/// 渲染为 Markdown 报告。
pub fn render_markdown(reports : Array[@orchestrate.HealthReport], title : String) -> String {
  let s = StringBuilder()
  s.write_string("# " + title + "\n\n")
  s.write_string("| 对象 | 归因 | 可用 | 文档 | 健康 |\n")
  s.write_string("|---|---|---|---|---|\n")
  for r in reports {
    s.write_string("| " + r.subject + " | " + r.verdict_mark + " " + r.verdict + " | ")
    s.write_string(if r.usable { "✅" } else { "❌" })
    s.write_string(" | ")
    s.write_string(if r.has_docs {
      r.docs_passed.to_string() + "过/" + r.docs_failed.to_string() + "失"
    } else {
      "—"
    })
    s.write_string(" | ")
    s.write_string(if r.healthy { "✅" } else { "❌" })
    s.write_string(" |\n")
  }
  s.write_string("\n")
  let sum = summarize(reports)
  s.write_string("**统计**：" + sum.total.to_string() + " 个对象，" + sum.usable.to_string())
  s.write_string(" 个可用，" + sum.unhealthy.to_string() + " 个不健康。\n")
  s.to_string()
}

///|
/// 渲染为 JSON 数组。
pub fn render_json(reports : Array[@orchestrate.HealthReport]) -> String {
  let mut s = "["
  let mut first = true
  for r in reports {
    if first {
      first = false
    } else {
      s = s + ", "
    }
    s = s + @orchestrate.to_json(r)
  }
  s + "]"
}

// ---------- 单元测试 ----------

test "summarize 统计正确" {
  let a = @orchestrate.make_health_report("a/b", "Verified", "", "✅", true, 2, 0, true)
  let b = @orchestrate.make_health_report("c/d", "ToolchainMismatch", "", "🚫", false, 0, 0, false)
  let c = @orchestrate.make_health_report("e/f", "Verified", "", "✅", true, 1, 2, true)
  let sum = summarize([a, b, c])
  assert_eq(sum.total, 3)
  assert_eq(sum.usable, 2)
  assert_eq(sum.unhealthy, 2)
  assert_eq(sum.docs_failed_total, 2)
}

test "render_markdown 含表头与统计" {
  let a = @orchestrate.make_health_report("a/b", "Verified", "", "✅", true, 2, 0, true)
  let md = render_markdown([a], "测试报告")
  assert_true(md.contains("| 对象 | 归因 |"))
  assert_true(md.contains("**统计**：1 个对象，1 个可用，0 个不健康"))
}

test "render_json 输出数组" {
  let a = @orchestrate.make_health_report("a/b", "Verified", "", "✅", true, 2, 0, true)
  let j = render_json([a, a])
  assert_true(j.has_prefix("["))
  assert_true(j.has_suffix("]"))
  assert_true(j.contains("\"subject\":\"a/b\""))
}

test "render_json 空数组" {
  let j = render_json([])
  assert_eq(j, "[]")
}

// ---------- 报告合并边界用例（A3 补强） ----------

test "summarize 空数组返回全 0" {
  let sum = summarize([])
  assert_eq(sum.total, 0)
  assert_eq(sum.usable, 0)
  assert_eq(sum.unhealthy, 0)
  assert_eq(sum.docs_failed_total, 0)
}

test "summarize 仅累加有文档的失败块" {
  let a = @orchestrate.make_health_report("a/b", "Verified", "", "✅", true, 2, 0, true)
  let b = @orchestrate.make_health_report("c/d", "Verified", "", "✅", true, 0, 0, false)
  let c = @orchestrate.make_health_report("e/f", "Verified", "", "✅", true, 1, 3, true)
  let sum = summarize([a, b, c])
  assert_eq(sum.docs_failed_total, 3)
  assert_eq(sum.total, 3)
}

test "render_markdown 无文档列显示横杠" {
  let a = @orchestrate.make_health_report("a/b", "Verified", "", "✅", true, 0, 0, false)
  let md = render_markdown([a], "报告")
  assert_true(md.contains("| — |"))
}

test "render_markdown 有文档列显示通过/失败缩写" {
  let a = @orchestrate.make_health_report("a/b", "Verified", "", "✅", true, 3, 1, true)
  let md = render_markdown([a], "报告")
  assert_true(md.contains("| 3过/1失 |"))
}

test "render_markdown 空数组" {
  let md = render_markdown([], "空报告")
  assert_true(md.contains("**统计**：0 个对象，0 个可用，0 个不健康"))
}

test "render_markdown 多个对象逐行渲染" {
  let a = @orchestrate.make_health_report("a/b", "Verified", "", "✅", true, 2, 0, true)
  let b = @orchestrate.make_health_report("c/d", "NoManifest", "", "❌", false, 0, 0, false)
  let md = render_markdown([a, b], "报告")
  assert_true(md.contains("| a/b |"))
  assert_true(md.contains("| c/d |"))
  assert_true(md.contains("1 个可用，1 个不健康"))
}

test "render_json 多对象以逗号分隔" {
  let a = @orchestrate.make_health_report("a/b", "Verified", "", "✅", true, 2, 0, true)
  let b = @orchestrate.make_health_report("c/d", "NoManifest", "", "❌", false, 0, 0, false)
  let j = render_json([a, b])
  assert_true(j.contains("}, {"))
  assert_true(j.has_prefix("["))
  assert_true(j.has_suffix("]"))
}

// ---------- 边界补强：空输入 / 多对象 / 极端数据 ----------

test "render_markdown 空数组以标题开头" {
  let md = render_markdown([], "空标题")
  assert_true(md.has_prefix("# 空标题"))
  assert_true(md.contains("| 对象 | 归因 |"))
}

test "render_markdown 三个混合对象逐行渲染且统计累加" {
  let a = @orchestrate.make_health_report("a/b", "Verified", "", "✅", true, 5, 0, true)
  let b = @orchestrate.make_health_report("c/d", "Unsafe", "", "🔒", false, 0, 0, false)
  let c = @orchestrate.make_health_report("e/f", "Verified", "", "✅", true, 3, 2, true)
  let md = render_markdown([a, b, c], "混合")
  assert_true(md.contains("| a/b |"))
  assert_true(md.contains("| c/d |"))
  assert_true(md.contains("| e/f |"))
  // total=3, usable=2 (a/c 可用), unhealthy=2 (b/c 不健康), docs_failed_total=2
  assert_true(md.contains("3 个对象，2 个可用，2 个不健康"))
  let sum = summarize([a, b, c])
  assert_eq(sum.docs_failed_total, 2)
}

test "空字符串 subject 原样出现在单元格" {
  let a = @orchestrate.make_health_report("", "Verified", "", "✅", true, 0, 0, false)
  let md = render_markdown([a], "T")
  // subject 为空 → 该行第一格为空，第二格形如 "| ✅ Verified |"
  assert_true(md.contains("|  | ✅ Verified"))
}

test "超长 subject（200 字符）原样渲染" {
  let long_subj = "x".repeat(200)
  let a = @orchestrate.make_health_report(long_subj, "Verified", "", "✅", true, 0, 0, false)
  let md = render_markdown([a], "T")
  assert_true(md.contains(long_subj))
}

test "0 与极大文档计数渲染与统计" {
  let a = @orchestrate.make_health_report("p/q", "Verified", "", "✅", true, 0, 0, true)
  let b = @orchestrate.make_health_report("r/s", "Verified", "", "✅", true, 123456789, 987654321, true)
  let md = render_markdown([a, b], "T")
  assert_true(md.contains("| 0过/0失 |"))
  assert_true(md.contains("| 123456789过/987654321失 |"))
  let sum = summarize([a, b])
  assert_eq(sum.docs_failed_total, 987654321)
}

test "usable=false 可用列渲染 ❌" {
  let a = @orchestrate.make_health_report("p/q", "NoManifest", "", "❌", false, 0, 0, false)
  let md = render_markdown([a], "T")
  // 可用列与健康列都应为 ❌
  assert_true(md.contains("| ❌ | — | ❌ |"))
}

// ---------- 边界补强：表格竖线/换行转义（现状刻画，附 bug 记录） ----------

// 已知问题（仅记录，不改源码）：render_markdown 未对 subject 单元格做
// Markdown 转义，单元格内含 '|' 会破坏表格列数；含 '\n' 会直接折断表格行。
// 以下用例先刻画"当前未转义"的真实行为，保证基线稳定，待源码补转义后再升级断言。
test "现状刻画：单元格内含竖线 | 原样输出（未转义，已知 bug）" {
  let a = @orchestrate.make_health_report("a|b", "Verified", "", "✅", true, 0, 0, false)
  let md = render_markdown([a], "T")
  // 当前实现直接拼接原始 subject
  assert_true(md.contains("| a|b |"))
}

test "现状刻画：单元格内含换行符原样输出（未转义，已知 bug）" {
  let a = @orchestrate.make_health_report("a\nb", "Verified", "", "✅", true, 0, 0, false)
  let md = render_markdown([a], "T")
  // 当前实现不转义换行，原始 subject 中的 \n 会直接出现在输出里
  assert_true(md.contains("a\nb"))
}

// ---------- 边界补强：render_json 字段完备性 ----------

test "render_json 包含布尔与数字字段" {
  let a = @orchestrate.make_health_report("p/q", "Unsafe", "含 FFI", "🔒", false, 0, 3, false)
  let j = render_json([a])
  assert_true(j.contains("\"usable\":false"))
  assert_true(j.contains("\"has_docs\":false"))
  assert_true(j.contains("\"healthy\":false"))
  assert_true(j.contains("\"docs_passed\":0"))
  assert_true(j.contains("\"docs_failed\":3"))
}

test "render_json 中 verdict_explain 的引号被转义" {
  let a = @orchestrate.make_health_report("p/q", "Verified", "say \"hi\"", "✅", true, 1, 0, true)
  let j = render_json([a])
  // orchestrate.escape 只转引号与反斜杠
  assert_true(j.contains("\"verdict_explain\":\"say \\\"hi\\\"\""))
}
