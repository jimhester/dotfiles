-- Colemak keyboard remappings
-- Rotate keys to get qwerty "hjkl" movement on colemak
local keymap = vim.keymap.set

-- Movement keys (hjkl on qwerty -> hnei on colemak)
-- Using "" applies to normal, visual, select, and operator-pending modes
keymap("", "n", "<Down>", { noremap = true })
keymap("", "e", "<Up>", { noremap = true })
keymap("", "i", "<Right>", { noremap = true })

-- Move displaced keys to qwerty positions (all modes)
keymap("", "k", "n", { noremap = true })  -- next search
keymap("", "K", "N", { noremap = true })  -- prev search
keymap("", "l", "u", { noremap = true })  -- undo
keymap("", "L", "U", { noremap = true })  -- undo line
keymap("", "N", "J", { noremap = true })  -- join lines
keymap("", "E", "K", { noremap = true })  -- keyword lookup
keymap("", "I", "L", { noremap = true })  -- move to bottom of screen

-- Insert mode remaps (normal mode only)
keymap("n", "u", "i", { noremap = true })  -- insert
keymap("n", "U", "I", { noremap = true })  -- insert at beginning

-- e -> j (end of word) - all modes
keymap("", "j", "e", { noremap = true })
keymap("", "J", "E", { noremap = true })

-- Window movement with Colemak
keymap("n", "<C-w>n", "<C-w>j", { noremap = true })
keymap("n", "<C-w>i", "<C-w>l", { noremap = true })
keymap("n", "<C-w>e", "<C-w>k", { noremap = true })

-- Map back stolen window commands
keymap("n", "<C-w>k", "<C-w>n", { noremap = true })
keymap("n", "<C-w>l", "<C-w>i", { noremap = true })

-- Movement with count adds to jumplist (from vimrc.local)
keymap("n", "n", function()
  if vim.v.count > 1 then
    return "m'" .. vim.v.count .. "j"
  else
    return "j"
  end
end, { noremap = true, silent = true, expr = true })

keymap("n", "e", function()
  if vim.v.count > 1 then
    return "m'" .. vim.v.count .. "k"
  else
    return "k"
  end
end, { noremap = true, silent = true, expr = true })
