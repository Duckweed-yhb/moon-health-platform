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
