-- Scrub inherited git environment so subprocesses (gitsigns, fugitive, LSP
-- servers, :terminal) can never act on a leaked GIT_INDEX_FILE. When nvim is
-- launched as git's editor (EDITOR=nvim during `git commit`), git exports
-- GIT_INDEX_FILE/GIT_DIR/etc; a child git run in another repo would otherwise
-- write that repo's tree into the committing repo's index and corrupt it.
-- See docs/r-lsp-git-index-corruption.md. Editors and plugins rediscover the
-- repo from the buffer path, so dropping the inherited git env is safe.
for _, v in ipairs({
  "GIT_INDEX_FILE", "GIT_DIR", "GIT_WORK_TREE",
  "GIT_OBJECT_DIRECTORY", "GIT_COMMON_DIR", "GIT_PREFIX", "GIT_NAMESPACE",
}) do
  vim.env[v] = nil
end

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Set leader before plugins
vim.g.mapleader = "\\"
vim.g.maplocalleader = "\\"

-- Load plugins
require("lazy").setup("plugins")

-- Load settings
require("settings")

-- Load keymaps
require("keymaps")

-- Load colemak remappings
require("colemak")
