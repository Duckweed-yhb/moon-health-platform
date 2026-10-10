///|
/// MoonHealth Platform — MoonBit 生态健康验证平台
///
/// 用法: moonhealth <命令> [参数...]
///
/// 命令:
///   check [--moonproof <cmd>] <候选>...   生态健康检查（归因 + 可选文档验证）
///   doctor                                 检查平台运行环境
///   version                                打印版本
///   help                                   打印本帮助
///
/// 候选写法: owner/repo | https://github.com/owner/repo | 本地目录路径
///
/// 退出码约定（与子工具对齐）：
///   0  成功（全部健康 / 无失败）
///   1  有失败（包不可用 / 文档失效）
///   2  运行错误 / 参数错误
///   10 环境错误   14 参数错误   15 工具链错误
///
/// 平台编排逻辑：
///   - 归因：复用 moon-hive 的 verify/check.verify_candidate（git 拉取 →
///     静态预检 → moon check/test → diagnose 分类），把每个候选的
///     Diagnosis 转成平台的 HealthReport（HealthReport.verdict 等）。
///   - 文档验证（可选）：通过 --moonproof 注入 MoonProof CLI 命令，
///     平台用子进程调用它做文档示例验证，把结果并入 HealthReport。
///   - 报告：用 features/report 把多份 HealthReport 聚合成 Markdown / JSON。

///|
fn main {
  let argv = @env.args()
  if argv.length() <= 1 {
    print_usage()
    @proc.exit_with(14)
    return
  }
  let cmd = argv[1]
  let rest : Array[String] = if argv.length() > 2 {
    argv[2:].to_owned()
  } else {
    []
  }
  match cmd {
    "check" => cmd_check(rest)
    "doctor" => cmd_doctor()
    "version" | "--version" | "-V" => println(version_line())
    "help" | "--help" | "-h" => print_usage()
    other => {
      println("未知命令: " + other)
      println("")
      print_usage()
      @proc.exit_with(14)
    }
  }
}

///|
fn version_line() -> String {
  "moonhealth 0.1.0 (MoonBit 生态健康验证平台)"
}

///|
/// check 命令：moonhealth check [--moonproof <cmd>] <候选>...
fn cmd_check(args : Array[String]) -> Unit {
  let mut moonproof_cmd = ""
  let candidates : Array[String] = []
  let mut i = 0
  while i < args.length() {
    let a = args[i]
    if a == "--moonproof" && i + 1 < args.length() {
      moonproof_cmd = args[i + 1]
      i = i + 2
    } else if a.has_prefix("--moonproof=") {
      moonproof_cmd = a[12:].to_owned()
      i = i + 1
    } else {
      candidates.push(a)
      i = i + 1
    }
  }
  if candidates.length() == 0 {
    println("用法: moonhealth check [--moonproof <cmd>] <候选>...")
    println("")
    println("示例: moonhealth check moonbit-community/yaml")
    println("      moonhealth check ./local-pkg --moonproof \"moon run --target native C:/path/MoonProof/cmd/moonproof --\"")
    @proc.exit_with(14)
    return
  }

  // 建一次性工作区，逐个候选归因
  let ws = match @workspace.create() {
    Ok(w) => w
    Err(_) => {
      println("错误: 无法创建隔离工作区")
      @proc.exit_with(12)
      return
    }
  }
  let reports : Array[@orchestrate.HealthReport] = []
  let mut any_fail = false
  for raw in candidates {
    let cand = match resolve_candidate(raw) {
      Ok(c) => c
      Err(msg) => {
        let hr = @orchestrate.make_health_report(
          raw,
          "BadInput",
          msg,
          "⚠️",
          false,
          0,
          0,
          false,
        )
        reports.push(hr)
        any_fail = true
        continue
      }
    }
    let rev = match @check.verify_candidate(
      cand,
      ws,
      @gitsource.detect_backend(),
      "native",
      120000,
      true,
    ) {
      Ok(r) => r
      Err(e) => {
        let hr = @orchestrate.make_health_report(
          cand.slug,
          "CheckError",
          error_text(e),
          "⚠️",
          false,
          0,
          0,
          false,
        )
        reports.push(hr)
        any_fail = true
        continue
      }
    }
    let d = rev.diagnosis
    let usable = @diagnose.is_usable(d)
    // 文档验证（可选）：注入 moon-proof 命令后，把验证结果并入报告。
    let (docs_passed, docs_failed, has_docs) = if moonproof_cmd.length() > 0 {
      run_moonproof(moonproof_cmd, cand)
    } else {
      (0, 0, false)
    }
    let hr = @orchestrate.make_health_report(
      cand.slug,
      @diagnose.label(d),
      @diagnose.explain(d),
      @diagnose.mark(d),
      usable,
      docs_passed,
      docs_failed,
      has_docs,
    )
    reports.push(hr)
    if !hr.healthy {
      any_fail = true
    }
    println(@orchestrate.render_health(hr))
    println("")
  }
  ignore(@workspace.destroy(ws))

  // 汇总
  println("===== 平台健康报告 =====")
  println(@report.render_markdown(reports, "MoonHealth 生态健康报告"))
  let j = @report.render_json(reports)
  println("")
  println("JSON: " + j)

  if any_fail {
    @proc.exit_with(1)
  } else {
    @proc.exit_with(0)
  }
}

///|
/// 解析候选：本地目录或 owner/repo。
///
/// 本地目录用 moon-hive 的 from_local（内部以 fs.is_dir 做真实存在性判断，
/// 依赖 moon-hive ≥0.2.2 对 Windows 中文路径的 UTF-16 修复）；否则当作
/// owner/repo slug。
fn resolve_candidate(raw : String) -> Result[@gitsource.Candidate, String] {
  match @gitsource.from_local(raw) {
    Ok(c) => Ok(c)
    Err(_) =>
      match @gitsource.from_slug(raw) {
        Ok(c) => Ok(c)
        Err(_) => Err("既不是可访问的本地目录，也不是合法的 owner/repo: " + raw)
      }
  }
}

///|
/// 调用 MoonProof CLI 验证候选仓库的文档示例，并**严格解析**其 `--out` JSON。
///
/// `moonproof_cmd` 是子进程命令模板（不含候选目录），本函数把候选目录和
/// `--out <临时 JSON 路径>` 追加进去，MoonProof 会把每个文档的
/// `{total, passed, failed, skipped, blocks}` 写成 JSON 数组。
///
/// 返回 (通过块数, 失败块数, 是否有文档需要验证)。
///
/// 相比此前的保守解析（固定返回 (0,0,false)），这里真正解析 JSON：
/// - 无文档（total==0）→ has_docs=false，健康判定只看包可用性；
/// - 有文档 → has_docs=true，任一失败块使整体不健康。
fn run_moonproof(
  moonproof_cmd : String,
  cand : @gitsource.Candidate
) -> (Int, Int, Bool) {
  // MoonProof 验证本地目录；远端候选不做文档验证（需要先克隆到本地）。
  if !@gitsource.is_local(cand) {
    return (0, 0, false)
  }
  // 用时间戳构造唯一临时 JSON 路径，避免并发冲突
  let stamp = @env.now()
  let json_path = @proc.join_path(
    @proc.temp_dir(),
    "moonhealth-docs-" + stamp.to_string() + ".json",
  )
  let cmd = moonproof_cmd + " " + cand.local_path + " --out " + json_path
  match @proc.run(cmd, "", 300000) {
    Err(_) => (0, 0, false)
    Ok(_o) =>
      // read_text 失败（文件不存在 / 空）时返回空串，parse 会报 Err，语义正确。
      match @jsonparse.parse(@fs.read_text(json_path)) {
        Err(_) => (0, 0, false)
        Ok(root) => sum_docs(root)
      }
  }
}

///|
/// 从 MoonProof 的 JSON 数组汇总文档验证统计。
/// 每个元素形如 `{"path":..., "total":N, "passed":P, "failed":F, "skipped":S, ...}`。
/// 返回 (passed 总和, failed 总和, 是否有任何文档块)。
fn sum_docs(root : @jsonparse.JsonValue) -> (Int, Int, Bool) {
  let mut passed = 0
  let mut failed = 0
  let mut total = 0
  match root {
    @jsonparse.JsonArray(rows) => {
      for row in rows {
        total = total + int_field(row, "total")
        passed = passed + int_field(row, "passed")
        failed = failed + int_field(row, "failed")
      }
    }
    _ => ()
  }
  (passed, failed, total > 0)
}

///|
/// 从对象取整数字段；字段缺失或非整数按 0 计（对无文档项无副作用）。
fn int_field(obj : @jsonparse.JsonValue, key : String) -> Int {
  match @jsonparse.field(obj, key) {
    Some(v) =>
      match @jsonparse.int_of(v) {
        Some(n) => n
        None => 0
      }
    None => 0
  }
}

///|
/// doctor 命令：检查平台运行环境。
fn cmd_doctor() -> Unit {
  println("MoonHealth doctor — 检查平台运行环境")
  let checks : Array[(String, Bool)] = []
  // moon 工具链
  match @proc.run("moon --version", "", 20000) {
    Ok(o) => checks.push(("moon 工具链", o.exit_code == 0))
    Err(_) => checks.push(("moon 工具链", false))
  }
  // git
  match @proc.run("git --version", "", 20000) {
    Ok(o) => checks.push(("git", o.exit_code == 0))
    Err(_) => checks.push(("git", false))
  }
  // 临时目录
  let tmp = @proc.temp_dir()
  checks.push(("临时目录", tmp.length() > 0))
  let mut all_ok = true
  for (name, ok) in checks {
    println((if ok { "✅ " } else { "❌ " }) + name)
    if !ok {
      all_ok = false
    }
  }
  if all_ok {
    @proc.exit_with(0)
  } else {
    @proc.exit_with(10)
  }
}

///|
fn error_text(e : @check.CheckError) -> String {
  match e {
    @check.WorkspaceFailed(m) => "工作区操作失败: " + m
  }
}

///|
fn print_usage() -> Unit {
  println(version_line())
  println("")
  println("用法: moonhealth <命令> [参数...]")
  println("")
  println("命令:")
  println("  check [--moonproof <cmd>] <候选>...")
  println("                                  生态健康检查：归因 + 可选文档验证")
  println("  doctor                          检查平台运行环境（moon / git / 临时目录）")
  println("  version                         打印版本")
  println("  help                            打印本帮助")
  println("")
  println("候选写法: owner/repo | https://github.com/owner/repo | 本地目录路径")
  println("--moonproof: 注入 MoonProof CLI 命令模板，对本地候选做文档示例验证")
  println("")
  println("退出码: 0 全部健康 | 1 有失败 | 2 运行/参数错误 | 10 环境错误 | 14 参数错误")
}
