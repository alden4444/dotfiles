-- SET LEADER KEY
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- BOOTSTRAP LAZY.NVIM
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- KEYBINDINGS
vim.keymap.set("i", "jj", "<Esc>", { noremap = true, silent = true })

-- GENERAL SETTINGS FOR COMFORTABLE NOTETAKING
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.wrap = true
vim.opt.termguicolors = true
vim.opt.conceallevel = 2

-- DYNAMIC WALLUST COLOR LOADER
-- Reads directly from the same colors.json file your Quickshell uses
local function apply_wallust_theme()
  local json_path = vim.fn.expand("~/.config/quickshell/colors.json")
  local file = io.open(json_path, "r")
  if not file then return end

  local content = file:read("*a")
  file:close()

  -- Simple JSON parsing decoder for Wallust strings
  local json = vim.json.decode(content)
  if not json then return end

  -- Clear existing highlights to build our theme
  vim.cmd("highlight clear")
  vim.g.colors_name = "wallust_dynamic"

  -- Core Editor Colors (Pulled cleanly from your layout environment)
  vim.api.nvim_set_hl(0, "Normal", { fg = json.foreground, bg = json.background })
  vim.api.nvim_set_hl(0, "NormalFloat", { fg = json.foreground, bg = json.background })
  vim.api.nvim_set_hl(0, "LineNr", { fg = json.color8 })
  vim.api.nvim_set_hl(0, "CursorLineNr", { fg = json.color6, bold = true })

  -- Syntax Highlighting Groups (Mapped to standard ANSI slots)
  vim.api.nvim_set_hl(0, "Comment", { fg = json.color8, italic = true })
  vim.api.nvim_set_hl(0, "String", { fg = json.color2 })
  vim.api.nvim_set_hl(0, "Function", { fg = json.color4 })
  vim.api.nvim_set_hl(0, "Keyword", { fg = json.color5, bold = true })
  vim.api.nvim_set_hl(0, "Statement", { fg = json.color1 })
  vim.api.nvim_set_hl(0, "Identifier", { fg = json.color3 })
  vim.api.nvim_set_hl(0, "Type", { fg = json.color6 })

  -- HackTheBox Notes Custom Layout Groups
  vim.api.nvim_set_hl(0, "RenderMarkdownH1", { fg = json.color1, bold = true })
  vim.api.nvim_set_hl(0, "RenderMarkdownH2", { fg = json.color2, bold = true })
  vim.api.nvim_set_hl(0, "RenderMarkdownH3", { fg = json.color3, bold = true })
  vim.api.nvim_set_hl(0, "RenderMarkdownBullet", { fg = json.color6, bold = true })
  vim.api.nvim_set_hl(0, "RenderMarkdownCode", { bg = json.color0 })
  vim.api.nvim_set_hl(0, "RenderMarkdownCodeInline", { fg = json.color4, bg = json.color0 })
end

-- Run it immediately on startup
apply_wallust_theme()

-- Automatically reload the theme whenever you focus back into NeoVim
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "WinEnter" }, {
  pattern = "*",
  callback = function()
    apply_wallust_theme()
  end,
})

-- PLUGIN CONFIGURATION
require("lazy").setup({

  -- TREE-SITTER (Handles notes layout elements)
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    main = "nvim-treesitter",
    opts = {
      ensure_installed = { "markdown", "markdown_inline", "bash", "python" },
      highlight = { enable = true },
    },
  },

  -- MARKDOWN RENDERING
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {},
  },

  -- TELESCOPE
  {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.8',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      local builtin = require('telescope.builtin')
      vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = "Find Files" })
      vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = "Live Grep" })
      vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = "Buffers" })
    end
  },

  -- LUASNIP
  {
    "L3MON4D3/LuaSnip",
    version = "v2.*",
    build = "make install_jsregexp",
    config = function()
      local ls = require("luasnip")
      vim.keymap.set({"i", "s"}, "<C-k>", function() if ls.expand_or_jumpable() then ls.expand_or_jump() end end, {silent = true})
      vim.keymap.set({"i", "s"}, "<C-j>", function() if ls.jumpable(-1) then ls.jump(-1) end end, {silent = true})
    end,
  },

  -- VIMWIKI
  {
    'vimwiki/vimwiki',
    init = function()
      vim.g.vimwiki_list = {
        {
          path = '~/notes/',
          syntax = 'markdown',
          ext = '.md',
        }
      }
      vim.g.vimwiki_global_ext = 0
    end
  },
})
