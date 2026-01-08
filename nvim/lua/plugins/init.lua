return {
  -- Colorscheme
  {
    "ishan9299/nvim-solarized-lua",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme("solarized")
    end,
  },

  -- Treesitter for syntax highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      -- New API for nvim-treesitter 1.0+
      vim.treesitter.language.register("markdown", "mdx")

      -- Enable treesitter highlighting
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "r", "lua", "vim", "bash", "python", "markdown", "javascript", "typescript" },
        callback = function()
          pcall(vim.treesitter.start)
        end,
      })
    end,
  },

  -- Tmux navigator (colemak layout)
  {
    "christoomey/vim-tmux-navigator",
    init = function()
      vim.g.tmux_navigator_no_mappings = 1
    end,
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
    },
    keys = {
      { "<c-h>", "<cmd>TmuxNavigateLeft<cr>", mode = { "n", "t" } },
      { "<c-n>", "<cmd>TmuxNavigateDown<cr>", mode = { "n", "t" } },
      { "<c-e>", "<cmd>TmuxNavigateUp<cr>", mode = { "n", "t" } },
      { "<c-'>", "<cmd>TmuxNavigateRight<cr>", mode = { "n", "t" } },
    },
  },

  -- File explorer
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup({
        view = { width = 30 },
      })
      vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { silent = true })
    end,
  },

  -- Fuzzy finder
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local builtin = require("telescope.builtin")
      vim.keymap.set("n", "<leader>ff", builtin.find_files, {})
      vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
      vim.keymap.set("n", "<leader>fb", builtin.buffers, {})
      vim.keymap.set("n", "<leader>fh", builtin.help_tags, {})
      vim.keymap.set("n", "<C-p>", builtin.find_files, {})
    end,
  },

  -- Git signs in gutter
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup()
    end,
  },

  -- Status line
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({
        options = { theme = "solarized_light" },
      })
    end,
  },

  -- LSP Support (using native vim.lsp.config for Neovim 0.11+)
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls", "r_language_server", "clangd", "pyright" },
      })

      -- Configure LSP servers using native Neovim API
      vim.lsp.config("lua_ls", {
        cmd = { vim.fn.stdpath("data") .. "/mason/bin/lua-language-server" },
      })
      vim.lsp.config("r_language_server", {
        cmd = { "r-languageserver" },
      })
      vim.lsp.config("clangd", {
        cmd = { vim.fn.stdpath("data") .. "/mason/bin/clangd" },
      })
      vim.lsp.config("pyright", {
        cmd = { vim.fn.stdpath("data") .. "/mason/bin/pyright-langserver", "--stdio" },
      })
      vim.lsp.enable({ "lua_ls", "r_language_server", "clangd", "pyright" })
    end,
  },

  -- Autocompletion
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
        }),
      })
    end,
  },

  -- R support (Nvim-R)
  {
    "R-nvim/R.nvim",
    lazy = false,
    config = function()
      local opts = {
        R_assign = 0,
        rconsole_width = 80,
        nvimpager = "no",
        user_maps_only = true,
      }
      require("r").setup(opts)

      -- Custom R keymaps
      vim.keymap.set("n", "<LocalLeader>rf", "<Plug>RStart", {})
      vim.keymap.set("n", "<LocalLeader>rq", "<Plug>RClose", {})
      vim.keymap.set("n", ",", "<Plug>RDSendLine", {})
      vim.keymap.set("v", ",", "<Plug>RSendSelection", {})
    end,
  },

  -- Commenting
  {
    "numToStr/Comment.nvim",
    config = function()
      require("Comment").setup()
    end,
  },

  -- Surround
  {
    "kylechui/nvim-surround",
    event = "VeryLazy",
    config = function()
      require("nvim-surround").setup()
    end,
  },

  -- Autopairs
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      require("nvim-autopairs").setup()
    end,
  },

  -- Git integration
  { "tpope/vim-fugitive" },

  -- Undo tree
  {
    "mbbill/undotree",
    config = function()
      vim.keymap.set("n", "<F5>", vim.cmd.UndotreeToggle)
    end,
  },

  -- Dispatch for async builds
  { "tpope/vim-dispatch" },

  -- Ripgrep search
  {
    "mileszs/ack.vim",
    config = function()
      vim.g.ackprg = "rg --vimgrep --no-heading"
    end,
  },
}
