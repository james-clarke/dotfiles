-- Settings the `lsp` plugin hands to every language server (installed to ~/.config/lite-xl/).
-- They live here rather than in a server's `settings` table because the plugin caches computed
-- settings for 5s under a key that ignores the server name: when two servers start together the
-- first one populates the cache with its (empty) settings and the second gets nothing. This file
-- is read for every server, so the cached table always carries these keys.
local core = require "core"

-- first existing interpreter wins; projects with neither fall back to system python
local function project_python(candidates)
  for _, rel in ipairs(candidates) do
    local path = core.project_dir .. "/" .. rel
    if system.get_file_info(path) then return path end
  end
end

return {
  basedpyright = {
    analysis = {
      -- basedpyright defaults to "recommended", which floods Django code with
      -- reportUnknown*/reportAny noise. "standard" matches upstream pyright.
      typeCheckingMode = "standard",
    },
  },
  python = {
    pythonPath = project_python { ".venv/bin/python", "venv/bin/python" },
  },
}
