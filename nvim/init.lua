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
