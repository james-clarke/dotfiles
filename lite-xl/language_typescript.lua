-- mod-version:3
-- TypeScript / TSX / JSX on top of the built-in JavaScript syntax. Replaces the lpm `language_ts`
-- addon, whose `/%g` rule treated every `a/b` as the start of a string. Reusing language_js keeps
-- its guarded regex-literal rule; only TypeScript keywords and file patterns are added here.
-- Linked into ~/.config/lite-xl/plugins/ by setup.py.
require "plugins.language_js"
local syntax = require "core.syntax"

local js = syntax.get("file.js")

local patterns = {
  { pattern = "interface%s+()[%a_][%w_]*", type = { "keyword", "keyword2" } },
  { pattern = "type%s+()[%a_][%w_]*()%s*=", type = { "keyword", "keyword2", "operator" } },
  { pattern = "enum%s+()[%a_][%w_]*",      type = { "keyword", "keyword2" } },
}
for _, p in ipairs(js.patterns) do table.insert(patterns, p) end

local symbols = {}
for k, v in pairs(js.symbols) do symbols[k] = v end
for _, k in ipairs {
  "abstract", "as", "asserts", "declare", "enum", "implements", "infer", "interface", "is",
  "keyof", "namespace", "override", "private", "protected", "public", "readonly", "satisfies",
  "type", "unique",
} do symbols[k] = "keyword" end
for _, k in ipairs {
  "any", "bigint", "boolean", "never", "number", "object", "string", "symbol", "unknown", "void",
} do symbols[k] = "keyword2" end

syntax.add {
  name = "TypeScript",
  files = { "%.tsx?$", "%.jsx$" },
  comment = js.comment,
  block_comment = js.block_comment,
  patterns = patterns,
  symbols = symbols,
}
