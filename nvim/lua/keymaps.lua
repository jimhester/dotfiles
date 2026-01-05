local keymap = vim.keymap.set

-- Remap semicolon and colon (from your vimrc.local)
keymap("n", ";", ":", { noremap = true })
keymap("n", ":", ";", { noremap = true })
keymap("v", ";", ":", { noremap = true })
keymap("v", ":", ";", { noremap = true })

-- Kill search highlight with leader-slash
keymap("n", "<leader>/", ":noh<CR>", { noremap = true, silent = true })

-- Toggle folding with leader-z
keymap("n", "<leader>z", "za", { noremap = true })
keymap("v", "<leader>z", "za", { noremap = true })

-- Save with s
keymap("n", "s", ":update<CR>", { noremap = true, silent = true })

-- Paste toggle (pastetoggle is removed in newer nvim, use :set paste manually if needed)

-- Replace text in visual mode with r
keymap("v", "r", '"_dP', { noremap = true })

-- Better window navigation (will be overridden by tmux-navigator)
keymap("n", "<C-h>", "<C-w>h", { noremap = true, silent = true })
keymap("n", "<C-j>", "<C-w>j", { noremap = true, silent = true })
keymap("n", "<C-k>", "<C-w>k", { noremap = true, silent = true })
keymap("n", "<C-l>", "<C-w>l", { noremap = true, silent = true })

-- Modeline function
vim.api.nvim_create_user_command("AppendModeline", function()
  local modeline = string.format(
    " vim: set ts=%d sw=%d tw=%d %set :",
    vim.bo.tabstop,
    vim.bo.shiftwidth,
    vim.bo.textwidth,
    vim.bo.expandtab and "" or "no"
  )
  local commentstring = vim.bo.commentstring
  if commentstring ~= "" then
    modeline = commentstring:gsub("%%s", modeline)
  end
  vim.api.nvim_buf_set_lines(0, -1, -1, false, { modeline })
end, {})
keymap("n", "<leader>ml", ":AppendModeline<CR>", { noremap = true, silent = true })
