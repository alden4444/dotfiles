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
  local json_path = vim.fn.expand("~/.config/quickshell-active/colors.json")
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

-- MATERIAL 3 EXPRESSIVE UI & ROUNDED CORNERS
vim.diagnostic.config({
  float = { border = "rounded" },
})

-- GUI / NEOVIDE CONFIGURATION (VS Code Smooth Scroll, Font, Padding & Material 3)
if vim.g.neovide then
  -- Set font to Google Sans Code
  vim.o.guifont = "Google Sans Code, FiraCode Nerd Font, Hack, monospace:h12"

  -- Window Padding (spacing from window edges so content isn't right at the top/sides)
  vim.g.neovide_padding_top = 16
  vim.g.neovide_padding_bottom = 16
  vim.g.neovide_padding_left = 16
  vim.g.neovide_padding_right = 16

  -- Enable VS Code style smooth scrolling & cursor animations
  vim.g.neovide_scroll_animation_length = 0.3
  vim.g.neovide_scroll_animation_far_lines = 1
  vim.g.neovide_cursor_animation_length = 0.13
  vim.g.neovide_cursor_trail_size = 0.8
  vim.g.neovide_cursor_antialiasing = true
end

-- PLUGIN CONFIGURATION
require("lazy").setup({
  { import = "plugins" },
})


