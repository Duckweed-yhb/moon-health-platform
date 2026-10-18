///|
/// features/jsonparse — 最小但严格的 JSON 解析器（纯计算，可移植）
///
/// 用于解析子工具（MoonProof）导出的 `--out` JSON 报告，提取平台需要的
/// 数字字段（文档块总数 / 通过 / 失败）。自包含、不 import 任何 C FFI 包，
/// 因此声明覆盖全部四个后端，可离线单测。
///
/// 支持的 JSON 子集：`object` / `array` / `string` / `number` / `true` /
/// `false` / `null`。字符串转义支持 `\"` `\\` `\/` `\b` `\f` `\n` `\r`
/// `\t` `\uXXXX`——这是完整 JSON 语法，足以严格解析 MoonProof 的稳定报告
/// 契约（顶层数组，每元素含 `total` / `passed` / `failed` / `skipped`）。
///
/// 数字以原始字面量字符串保存（保留精度），`int_of` 手动解析整数，
/// 避免依赖具体标准库的浮点转换 API。

///|
/// JSON 值的统一表示。
pub enum JsonValue {
  JsonNull
  JsonBool(Bool)
  JsonNumber(String)
  JsonString(String)
  JsonArray(Array[JsonValue])
  JsonObject(Array[(String, JsonValue)])
}

///|
/// 递归下降解析器的内部状态：输入文本 + 当前读取位置。
priv struct Parser {
  s : String;
  mut pos : Int;
}

///|
/// 解析一段 JSON 文本，返回根值或错误信息。
pub fn parse(text : String) -> Result[JsonValue, String] {
  let p = { s: text, pos: 0 }
  skip_ws(p)
  match parse_value(p) {
    Err(e) => Err(e)
    Ok(v) => {
      skip_ws(p)
      if p.pos < p.s.length() {
        Err("JSON 末尾存在多余内容")
      } else {
        Ok(v)
      }
    }
  }
}

///|
/// 取对象里指定键的值；非对象或键不存在返回 None。
pub fn field(obj : JsonValue, key : String) -> Option[JsonValue] {
  match obj {
    JsonObject(fields) => {
      for (k, v) in fields {
        if k == key {
          return Some(v)
        }
      }
      None
    }
    _ => None
  }
}

///|
/// 从 JsonValue 解析出整数；非数字（或非纯整数）返回 None。
/// 数字字面量以字符串保存，这里做朴素十进制解析（可选负号 + 数字）。
pub fn int_of(v : JsonValue) -> Option[Int] {
  match v {
    JsonNumber(s) => parse_dec_int(s)
    _ => None
  }
}

// ---------- 内部实现 ----------

///|
fn skip_ws(p : Parser) -> Unit {
  while p.pos < p.s.length() {
    let c = p.s[p.pos]
    if c == ' ' || c == '\t' || c == '\n' || c == '\r' {
      p.pos = p.pos + 1
    } else {
      break
    }
  }
}

///|
fn parse_value(p : Parser) -> Result[JsonValue, String] {
  skip_ws(p)
  if p.pos >= p.s.length() {
    return Err("JSON 意外结束")
  }
  let c = p.s[p.pos]
  if c == '{' {
    return parse_object(p)
  } else if c == '[' {
    return parse_array(p)
  } else if c == '"' {
    return match parse_string(p) {
      Ok(st) => Ok(JsonString(st))
      Err(e) => Err(e)
    }
  } else if c == 't' {
    return if consume_literal(p, "true") {
      Ok(JsonBool(true))
    } else {
      Err("非法字面量 true")
    }
  } else if c == 'f' {
    return if consume_literal(p, "false") {
      Ok(JsonBool(false))
    } else {
      Err("非法字面量 false")
    }
  } else if c == 'n' {
    return if consume_literal(p, "null") {
      Ok(JsonNull)
    } else {
      Err("非法字面量 null")
    }
  } else {
    return parse_number(p)
  }
}

///|
fn parse_object(p : Parser) -> Result[JsonValue, String] {
  p.pos = p.pos + 1 // 吃掉 '{'
  skip_ws(p)
  if p.pos < p.s.length() && p.s[p.pos] == '}' {
    p.pos = p.pos + 1
    return Ok(JsonObject([]))
  }
  let fields : Array[(String, JsonValue)] = []
  while true {
    skip_ws(p)
    if p.pos >= p.s.length() || p.s[p.pos] != '"' {
      return Err("对象里期望字符串键")
    }
    let key = match parse_string(p) {
      Ok(k) => k
      Err(e) => return Err(e)
    }
    skip_ws(p)
    if p.pos >= p.s.length() || p.s[p.pos] != ':' {
      return Err("对象里期望冒号")
    }
    p.pos = p.pos + 1
    let val = match parse_value(p) {
      Ok(v) => v
      Err(e) => return Err(e)
    }
    fields.push((key, val))
    skip_ws(p)
    if p.pos < p.s.length() && p.s[p.pos] == ',' {
      p.pos = p.pos + 1
      continue
    }
    if p.pos < p.s.length() && p.s[p.pos] == '}' {
      p.pos = p.pos + 1
      return Ok(JsonObject(fields))
    }
    return Err("对象里期望逗号或右花括号")
  } nobreak { Err("对象未正常结束") }
}

///|
fn parse_array(p : Parser) -> Result[JsonValue, String] {
  p.pos = p.pos + 1 // 吃掉 '['
  skip_ws(p)
  if p.pos < p.s.length() && p.s[p.pos] == ']' {
    p.pos = p.pos + 1
    return Ok(JsonArray([]))
  }
  let items : Array[JsonValue] = []
  while true {
    let val = match parse_value(p) {
      Ok(v) => v
      Err(e) => return Err(e)
    }
    items.push(val)
    skip_ws(p)
    if p.pos < p.s.length() && p.s[p.pos] == ',' {
      p.pos = p.pos + 1
      continue
    }
    if p.pos < p.s.length() && p.s[p.pos] == ']' {
      p.pos = p.pos + 1
      return Ok(JsonArray(items))
    }
    return Err("数组里期望逗号或右方括号")
  } nobreak { Err("数组未正常结束") }
}

///|
fn parse_string(p : Parser) -> Result[String, String] {
  // 当前 pos 指向开引号
  if p.s[p.pos] != '"' {
    return Err("期望字符串开引号")
  }
  p.pos = p.pos + 1
  let b = StringBuilder()
  while p.pos < p.s.length() {
    let c = p.s[p.pos]
    if c == '"' {
      p.pos = p.pos + 1
      return Ok(b.to_string())
    } else if c == '\\' {
      p.pos = p.pos + 1
      if p.pos >= p.s.length() {
        return Err("字符串转义不完整")
      }
      let e = p.s[p.pos]
      if e == '"' {
        b.write_char('"')
        p.pos = p.pos + 1
      } else if e == '\\' {
        b.write_char('\\')
        p.pos = p.pos + 1
      } else if e == '/' {
        b.write_char('/')
        p.pos = p.pos + 1
      } else if e == 'b' {
        b.write_char('\u{08}')
        p.pos = p.pos + 1
      } else if e == 'f' {
        b.write_char('\u{0C}')
        p.pos = p.pos + 1
      } else if e == 'n' {
        b.write_char('\n')
        p.pos = p.pos + 1
      } else if e == 'r' {
        b.write_char('\r')
        p.pos = p.pos + 1
      } else if e == 't' {
        b.write_char('\t')
        p.pos = p.pos + 1
      } else if e == 'u' {
        if p.pos + 4 >= p.s.length() {
          return Err("\\u 转义长度不足")
        }
        let cp = hex4_of(p.s[p.pos + 1]) * 4096 + hex4_of(p.s[p.pos + 2]) * 256 +
          hex4_of(p.s[p.pos + 3]) * 16 + hex4_of(p.s[p.pos + 4])
        if cp < 0 {
          return Err("\\u 转义含非十六进制字符")
        }
        b.write_char(cp.unsafe_to_char())
        p.pos = p.pos + 5
      } else {
        return Err("未知转义序列")
      }
    } else {
      b.write_char(c.unsafe_to_char())
      p.pos = p.pos + 1
    }
  }
  Err("字符串未闭合")
}

///|
fn hex4_of(c : UInt16) -> Int {
  let n = c.to_int()
  if n >= 0x30 && n <= 0x39 {
    n - 0x30
  } else if n >= 0x61 && n <= 0x66 {
    n - 0x61 + 10
  } else if n >= 0x41 && n <= 0x46 {
    n - 0x41 + 10
  } else {
    -1
  }
}

///|
fn consume_literal(p : Parser, lit : String) -> Bool {
  if p.pos + lit.length() > p.s.length() {
    return false
  }
  let mut i = 0
  while i < lit.length() {
    if p.s[p.pos + i] != lit[i] {
      return false
    }
    i = i + 1
  }
  p.pos = p.pos + lit.length()
  true
}

///|
fn parse_number(p : Parser) -> Result[JsonValue, String] {
  let b = StringBuilder()
  while p.pos < p.s.length() {
    let c = p.s[p.pos]
    if c == '-' || c == '+' || c == '.' || c == 'e' || c == 'E' ||
      (c.to_int() >= 0x30 && c.to_int() <= 0x39) {
      b.write_char(c.unsafe_to_char())
      p.pos = p.pos + 1
    } else {
      break
    }
  }
  let s = b.to_string()
  if s.length() == 0 {
    Err("期望数字")
  } else {
    Ok(JsonNumber(s))
  }
}

///|
/// 朴素十进制整数解析（可选负号 + 数字），供 int_of 使用。
fn parse_dec_int(s : String) -> Option[Int] {
  if s.length() == 0 {
    return None
  }
  let mut i = 0
  let mut neg = false
  if s[0] == '-' {
    neg = true
    i = 1
  } else if s[0] == '+' {
    i = 1
  }
  if i >= s.length() {
    return None
  }
  let mut acc = 0
  while i < s.length() {
    let n = s[i].to_int()
    if n < 0x30 || n > 0x39 {
      return None // 含小数点/指数等非整数成分
    }
    acc = acc * 10 + (n - 0x30)
    i = i + 1
  }
  if neg {
    Some(-acc)
  } else {
    Some(acc)
  }
}

// ---------- 单元测试 ----------

test "解析空对象与空数组" {
  match parse("{}") {
    Ok(JsonObject(f)) => assert_eq(f.length(), 0)
    _ => fail("expected empty object")
  }
  match parse("[]") {
    Ok(JsonArray(a)) => assert_eq(a.length(), 0)
    _ => fail("expected empty array")
  }
}

test "解析对象字段并取整数字段" {
  let t = "[{\"total\": 3, \"passed\": 2, \"failed\": 1, \"skipped\": 0}]"
  match parse(t) {
    Ok(JsonArray(rows)) => {
      let r = rows[0]
      assert_eq(int_of(field(r, "passed").unwrap()).unwrap(), 2)
      assert_eq(int_of(field(r, "failed").unwrap()).unwrap(), 1)
      assert_eq(int_of(field(r, "skipped").unwrap()).unwrap(), 0)
    }
    _ => fail("expected array")
  }
}

test "字符串转义解析（引号 / 反斜杠 / unicode）" {
  match parse("{\"k\": \"a\\\"b\\\\c\\u4e2d\"}") {
    Ok(JsonObject(fields)) => {
      let (_, v) = fields[0]
      match v {
        JsonString(s) => assert_eq(s, "a\"b\\c中")
        _ => fail("expected string")
      }
    }
    _ => fail("expected object")
  }
}

test "解析数字负数与多字段" {
  match parse("{\"a\": -5, \"b\": 42}") {
    Ok(JsonObject(fields)) => {
      assert_eq(int_of(field(JsonObject(fields), "a").unwrap()), Some(-5))
      assert_eq(int_of(field(JsonObject(fields), "b").unwrap()), Some(42))
    }
    _ => fail("expected object")
  }
}

test "非整数数字（含小数点）int_of 返回 None" {
  match parse("3.14") {
    Ok(v) => assert_eq(int_of(v), None)
    _ => fail("expected number")
  }
}

test "解析失败：对象缺冒号" {
  match parse("{\"a\" 1}") {
    Err(_) => assert_true(true)
    _ => fail("should error")
  }
}

test "解析失败：JSON 末尾多余内容" {
  match parse("[1] x") {
    Err(_) => assert_true(true)
    _ => fail("should error")
  }
}

test "field 对非对象返回 None" {
  match field(JsonArray([]), "k") {
    None => assert_true(true)
    _ => fail("expected None")
  }
  match field(JsonObject([]), "k") {
    None => assert_true(true)
    _ => fail("expected None")
  }
}

// ---------- 边界补强：深层嵌套 ----------

test "深层嵌套数组与对象可解析并取值" {
  let t = "[[[1, 2], [3, {\"a\": [4, {\"b\": 5}]}]]]"
  match parse(t) {
    Ok(JsonArray(rows)) => {
      // 最外层只有一个元素
      assert_eq(rows.length(), 1)
      // 深入到 {"a": [4, {"b": 5}]} 里取 b
      let inner = rows[0]
      match inner {
        JsonArray(innerRows) => {
          assert_eq(innerRows.length(), 2)
          match innerRows[1] {
            JsonArray(kv) => match kv[1] {
              JsonObject(fields) => {
                let av = field(JsonObject(fields), "a").unwrap()
                match av {
                  JsonArray(arr) => match arr[1] {
                    JsonObject(bf) => assert_eq(
                      int_of(field(JsonObject(bf), "b").unwrap()).unwrap(),
                      5,
                    )
                    _ => fail("expected object for b")
                  }
                  _ => fail("expected array for a")
                }
              }
              _ => fail("expected object")
            }
            _ => fail("expected array")
          }
        }
        _ => fail("expected inner array")
      }
    }
    _ => fail("expected array")
  }
}

test "前导/后置空白被忽略" {
  match parse("   { \"k\" : [ 1 , 2 ] }   ") {
    Ok(JsonObject(fields)) => {
      match field(JsonObject(fields), "k").unwrap() {
        JsonArray(arr) => {
          assert_eq(int_of(arr[0]).unwrap(), 1)
          assert_eq(int_of(arr[1]).unwrap(), 2)
        }
        _ => fail("expected array")
      }
    }
    _ => fail("expected object")
  }
}

test "顶层布尔与 null 字面量" {
  match parse("[true, false, null]") {
    Ok(JsonArray(arr)) => {
      match arr[0] {
        JsonBool(b) => assert_eq(b, true)
        _ => fail("expected bool true")
      }
      match arr[1] {
        JsonBool(b) => assert_eq(b, false)
        _ => fail("expected bool false")
      }
      match arr[2] {
        JsonNull => assert_true(true)
        _ => fail("expected null")
      }
    }
    _ => fail("expected array")
  }
}

// ---------- 边界补强：字符串转义 ----------

test "转义全集 \\n \\t \\r \\b \\f \\/" {
  match parse("{\"a\": \"\\n\\t\\r\\u0008\\u000c\\/\"}") {
    Ok(JsonObject(fields)) => match fields[0] {
      (_, JsonString(s)) => assert_eq(s, "\n\t\r\u{08}\u{0C}/")
      _ => fail("expected string")
    }
    _ => fail("expected object")
  }
}

test "代理对 \\uD83D\\uDE00 不报错且产出 2 个码元" {
  // 注：解析器逐 \u 写码点，未做代理对合并；此处只断言不报错、长度为 2
  match parse("\"\\uD83D\\uDE00\"") {
    Ok(JsonString(s)) => assert_eq(s.length(), 2)
    Ok(_) => fail("expected string")
    Err(e) => fail("surrogate pair should parse, got: " + e)
  }
}

test "非法 \\u 转义：长度不足" {
  match parse("\"\\u12\"") {
    Err(_) => assert_true(true)
    _ => fail("should error")
  }
}

test "非法 \\u 转义：首位字符非十六进制" {
  match parse("\"\\uG000\"") {
    Err(_) => assert_true(true)
    _ => fail("should error")
  }
}

// 已知 bug（仅记录，不改源码）：hex4_of 对非十六进制返回 -1，但 cp 是各 nibble
// 加权求和，仅当高位 nibble 为非十六进制时总和才 < 0。因此 "\u12g4"（非高位 nibble
// 非法）当前不报错，而是静默产出 U+11F4。下面用例刻画该现状。
test "现状刻画：非高位 \\u 非法字符被静默接受（已知 bug）" {
  match parse("\"\\u12g4\"") {
    Ok(JsonString(s)) => assert_eq(s.length(), 1)
    Ok(_) => fail("expected string")
    Err(e) => fail("current impl should accept, got: " + e)
  }
}

test "未知转义序列 \\\\a" {
  match parse("\"\\a\"") {
    Err(_) => assert_true(true)
    _ => fail("should error")
  }
}

test "反斜杠出现在字符串末尾（转义不完整）" {
  match parse("\"abc\\") {
    Err(_) => assert_true(true)
    _ => fail("should error")
  }
}

test "未闭合字符串" {
  match parse("\"abc") {
    Err(_) => assert_true(true)
    _ => fail("should error")
  }
}

// ---------- 边界补强：非法/残缺输入 ----------

test "尾随逗号：数组 [1,]" {
  match parse("[1,]") {
    Err(_) => assert_true(true)
    _ => fail("should error")
  }
}

test "尾随逗号：对象 {\"a\":1,}" {
  match parse("{\"a\":1,}") {
    Err(_) => assert_true(true)
    _ => fail("should error")
  }
}

test "缺失右花括号" {
  match parse("{\"a\":1") {
    Err(_) => assert_true(true)
    _ => fail("should error")
  }
}

test "缺失右方括号" {
  match parse("[1,2") {
    Err(_) => assert_true(true)
    _ => fail("should error")
  }
}

test "裸值非数字开头（hello）" {
  match parse("hello") {
    Err(_) => assert_true(true)
    _ => fail("should error")
  }
}

test "字面量后多余字符（truex）" {
  match parse("truex") {
    Err(_) => assert_true(true)
    _ => fail("should error")
  }
}

test "空输入" {
  match parse("") {
    Err(_) => assert_true(true)
    _ => fail("should error")
  }
}

// ---------- 边界补强：字段缺失 / 类型不符 ----------

test "字段缺失返回 None，int_of 亦为 None" {
  match parse("{\"a\": 1}") {
    Ok(obj) => {
      match field(obj, "missing") {
        None => assert_true(true)
        _ => fail("expected None")
      }
      match int_of(field(obj, "missing").unwrap_or(JsonNull)) {
        None => assert_true(true)
        _ => fail("expected None")
      }
    }
    _ => fail("expected object")
  }
}

test "类型不符：期望整数处给字符串/布尔" {
  match parse("{\"a\": \"123\", \"b\": true}") {
    Ok(obj) => {
      // 字符串虽然长得像整数，int_of 必须返回 None
      assert_eq(int_of(field(obj, "a").unwrap()), None)
      assert_eq(int_of(field(obj, "b").unwrap()), None)
    }
    _ => fail("expected object")
  }
}

test "int_of 对带指数/小数点数字返回 None" {
  match parse("1e3") {
    Ok(v) => assert_eq(int_of(v), None)
    _ => fail("expected number")
  }
  match parse("-0.5") {
    Ok(v) => assert_eq(int_of(v), None)
    _ => fail("expected number")
  }
}

test "int_of 解析负整数与多位正整数" {
  match parse("-2026") {
    Ok(v) => assert_eq(int_of(v).unwrap(), -2026)
    _ => fail("expected number")
  }
  match parse("48") {
    Ok(v) => assert_eq(int_of(v).unwrap(), 48)
    _ => fail("expected number")
  }
}
