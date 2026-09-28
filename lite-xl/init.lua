-- Lite XL user config. Lives in the dotfiles repo; ~/.config/lite-xl/init.lua is a symlink to it.
local core = require "core"
local config = require "core.config"
local style = require "core.style"
local common = require "core.common"

-- first existing path wins; lets one file serve Linux (~/.local/share/fonts) and macOS (~/Library/Fonts)
local function first_existing(paths)
  for _, p in ipairs(paths) do
    if system.get_file_info(p) then return p end
  end
end

-- absolute path of a tool, so a GUI launch with a minimal PATH still finds it; nil when not installed
local function bin(name)
  return first_existing {
    HOME .. "/.local/bin/" .. name,
    "/opt/homebrew/bin/" .. name,
    "/usr/local/bin/" .. name,
    "/usr/bin/" .. name,
    "/Library/Developer/CommandLineTools/usr/bin/" .. name,
  }
end

-- look (theme installed by setup.py via lpm, listed in os/lite-xl-plugins.txt)
-- core.reload_module "colors.ayu-light"
-- style.line_highlight = { common.color "#f0f0f0" }
local mono = first_existing {
  HOME .. "/.local/share/fonts/CommitMonoNerdFont/CommitMonoNerdFontMono-Regular.otf",
  HOME .. "/Library/Fonts/CommitMonoNerdFontMono-Regular.otf",
}
if mono then
  style.code_font = renderer.font.load(mono, 16 * SCALE)
  style.font = renderer.font.load(mono, 13 * SCALE)
end

-- editing
config.indent_size = 4
config.tab_type = "soft"
config.line_limit = 100
config.scroll_past_end = false
-- extend the built-in list (.git, node_modules, __pycache__, *.o, *.so, *.pyc, ...) rather than replace it
for _, p in ipairs { "^%.venv$", "^venv$", "^%.mypy_cache$", "^%.pytest_cache$", "^dist$", "^build$" } do
  table.insert(config.ignore_files, p)
end

-- language servers (plugin `lsp`, installed by setup.py via lpm). Binaries come from apt, npm or
-- Homebrew (clangd from Xcode CLT on macOS); a server whose binary is missing is not registered.
-- Nothing formats on save; Alt+Shift+F asks the server.
-- lintplus is only pulled in by lpm as an optional lsp dependency; with diagnostics off it does nothing
config.plugins.lintplus = false
config.plugins.toolbarview = false
local ok, lsp = pcall(require, "plugins.lsp")
if ok then
  -- LSP is for navigation and completion only: no inline squiggles, no status-bar count.
  -- Alt+E still lists a document's diagnostics on demand.
  config.plugins.lsp.show_diagnostics = false
  core.status_view:hide_items("lsp:diagnostics")

  local function server(spec)
    if spec.command[1] then lsp.add_server(spec) end
  end

  server {
    name = "basedpyright",
    language = "python",
    file_patterns = { "%.py$" },
    command = { bin "basedpyright-langserver", "--stdio" },
    -- typeCheckingMode and pythonPath live in .lite_lsp.lua (see the note there)
  }
  server {
    name = "typescript",
    language = {
      { id = "javascript", pattern = "%.[cm]?js$" },
      { id = "javascriptreact", pattern = "%.jsx$" },
      { id = "typescript", pattern = "%.ts$" },
      { id = "typescriptreact", pattern = "%.tsx$" },
    },
    file_patterns = { "%.jsx?$", "%.[cm]js$", "%.tsx?$" },
    command = { bin "typescript-language-server", "--stdio" },
  }
  server {
    name = "html",
    language = "html",
    file_patterns = { "%.html?$" },
    command = { bin "vscode-html-language-server", "--stdio" },
  }
  server {
    name = "css",
    language = "css",
    file_patterns = { "%.css$" },
    command = { bin "vscode-css-language-server", "--stdio" },
  }
  server {
    name = "clangd",
    language = "c",
    file_patterns = { "%.[ch]$" },
    command = { bin "clangd" },
  }
end
