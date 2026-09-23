-- Lite XL user config. Lives in the dotfiles repo; ~/.config/lite-xl/init.lua is a symlink to it.
local core = require "core"
local config = require "core.config"
local style = require "core.style"

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

-- look
local mono = first_existing {
  HOME .. "/.local/share/fonts/CommitMonoNerdFont/CommitMonoNerdFontMono-Regular.otf",
  HOME .. "/Library/Fonts/CommitMonoNerdFontMono-Regular.otf",
}
if mono then
  style.code_font = renderer.font.load(mono, 13 * SCALE)
  style.font = renderer.font.load(mono, 12 * SCALE)
end

-- editing
config.indent_size = 4
config.tab_type = "soft"
config.line_limit = 100
config.scroll_past_end = false
config.ignore_files = {
  "^%.git$", "^%.venv$", "^venv$", "^node_modules$", "^__pycache__$", "^%.mypy_cache$",
  "^%.pytest_cache$", "^dist$", "^build$", "^%.DS_Store$",
}

-- language servers (plugin `lsp`, installed by setup.py via lpm). Binaries come from apt, npm or
-- Homebrew (clangd from Xcode CLT on macOS); a server whose binary is missing is not registered.
-- Nothing formats on save; Alt+Shift+F asks the server.
local ok, lsp = pcall(require, "plugins.lsp")
if ok then
  config.plugins.lsp.show_diagnostics = true
  config.plugins.lsp.stop_unneeded_servers = true

  local function server(spec)
    if spec.command[1] then lsp.add_server(spec) end
  end

  server {
    name = "basedpyright",
    language = "python",
    file_patterns = { "%.py$" },
    command = { bin "basedpyright-langserver", "--stdio" },
    verbose = false,
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
    verbose = false,
  }
  server {
    name = "html",
    language = "html",
    file_patterns = { "%.html?$" },
    command = { bin "vscode-html-language-server", "--stdio" },
    verbose = false,
  }
  server {
    name = "css",
    language = "css",
    file_patterns = { "%.css$" },
    command = { bin "vscode-css-language-server", "--stdio" },
    verbose = false,
  }
  server {
    name = "clangd",
    language = "c",
    file_patterns = { "%.[ch]$" },
    command = { bin "clangd" },
    verbose = false,
  }
end
