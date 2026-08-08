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

-- GENERAL SETTINGS FOR COMFORTABLE NOTETAKING & EDITING
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.wrap = true
vim.opt.termguicolors = true
vim.opt.conceallevel = 2
vim.opt.showmatch = true -- Highlight complimentary matching brackets

-- FILETYPE DETECTION
vim.filetype.add({
  extension = {
    qml = "qml",
  },
})

-- Helper to check if a hex color is greyscale / monochrome
local function is_hex_monochrome(hex)
  if not hex or type(hex) ~= "string" or #hex < 7 then return true end
  local r = tonumber(hex:sub(2,3), 16) or 0
  local g = tonumber(hex:sub(4,5), 16) or 0
  local b = tonumber(hex:sub(6,7), 16) or 0
  return math.abs(r - g) < 22 and math.abs(g - b) < 22 and math.abs(r - b) < 22
end

-- DYNAMIC WALLUST COLOR LOADER WITH VIBRANT SYNTAX ACCENTS
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

  -- Detect if the system Wallust theme is monochrome greyscale
  local is_mono = is_hex_monochrome(json.color1) and is_hex_monochrome(json.color4)

  -- Vibrant syntax palette fallback (keeps background identical, makes code readable)
  local c1 = is_mono and "#f38ba8" or json.color1 -- Red / Coral (Statements/Objects)
  local c2 = is_mono and "#a6e3a1" or json.color2 -- Green (Strings)
  local c3 = is_mono and "#f9e2af" or json.color3 -- Yellow / Gold (Numbers/Constants)
  local c4 = is_mono and "#89b4fa" or json.color4 -- Blue / Sky (Functions/Properties)
  local c5 = is_mono and "#cba6f7" or json.color5 -- Violet / Purple (Keywords)
  local c6 = is_mono and "#94e2d5" or json.color6 -- Teal / Cyan (Types/Brackets)

  -- Clear existing highlights to build our theme
  vim.cmd("highlight clear")
  vim.g.colors_name = "wallust_dynamic"

  -- Core Editor Colors (Pulled cleanly from your layout environment)
  vim.api.nvim_set_hl(0, "Normal", { fg = json.foreground, bg = json.background })
  vim.api.nvim_set_hl(0, "NormalFloat", { fg = json.foreground, bg = json.background })
  vim.api.nvim_set_hl(0, "LineNr", { fg = json.color8 })
  vim.api.nvim_set_hl(0, "CursorLineNr", { fg = c6, bold = true })

  -- MATCHING BRACKET HIGHLIGHT (Glows in gold/yellow with underline)
  vim.api.nvim_set_hl(0, "MatchParen", { fg = c3, bg = json.color8, bold = true, underline = true })

  -- UI & Selection Highlights
  vim.api.nvim_set_hl(0, "Visual", { bg = json.color8, fg = json.foreground })
  vim.api.nvim_set_hl(0, "Search", { bg = c3, fg = json.background })
  vim.api.nvim_set_hl(0, "IncSearch", { bg = c5, fg = json.background })
  vim.api.nvim_set_hl(0, "Pmenu", { bg = json.color0, fg = json.foreground })
  vim.api.nvim_set_hl(0, "PmenuSel", { bg = c4, fg = json.background, bold = true })

  -- General Syntax Highlighting Groups
  vim.api.nvim_set_hl(0, "Comment", { fg = json.color8, italic = true })
  vim.api.nvim_set_hl(0, "String", { fg = c2 })
  vim.api.nvim_set_hl(0, "Function", { fg = c4 })
  vim.api.nvim_set_hl(0, "Keyword", { fg = c5, bold = true })
  vim.api.nvim_set_hl(0, "Statement", { fg = c1, bold = true })
  vim.api.nvim_set_hl(0, "Identifier", { fg = c3 })
  vim.api.nvim_set_hl(0, "Type", { fg = c6, bold = true })
  vim.api.nvim_set_hl(0, "Constant", { fg = c3, bold = true })
  vim.api.nvim_set_hl(0, "Number", { fg = c3 })
  vim.api.nvim_set_hl(0, "Boolean", { fg = c3, bold = true })
  vim.api.nvim_set_hl(0, "Delimiter", { fg = c6, bold = true })
  vim.api.nvim_set_hl(0, "Operator", { fg = c5 })
  vim.api.nvim_set_hl(0, "Special", { fg = c3 })
  vim.api.nvim_set_hl(0, "Directory", { fg = c4, bold = true })

  -- QML & Treesitter Specific Highlighting (Ensures vibrant QML components & properties)
  vim.api.nvim_set_hl(0, "qmlObject", { fg = c1, bold = true })
  vim.api.nvim_set_hl(0, "qmlType", { fg = c6, bold = true })
  vim.api.nvim_set_hl(0, "qmlProperty", { fg = c4 })
  vim.api.nvim_set_hl(0, "qmlBinding", { fg = c3 })

  vim.api.nvim_set_hl(0, "@property", { fg = c4 })
  vim.api.nvim_set_hl(0, "@field", { fg = c4 })
  vim.api.nvim_set_hl(0, "@type", { fg = c6, bold = true })
  vim.api.nvim_set_hl(0, "@type.builtin", { fg = c6, bold = true })
  vim.api.nvim_set_hl(0, "@constructor", { fg = c1, bold = true })
  vim.api.nvim_set_hl(0, "@punctuation.bracket", { fg = c6, bold = true })
  vim.api.nvim_set_hl(0, "@punctuation.delimiter", { fg = c6 })
  vim.api.nvim_set_hl(0, "@keyword", { fg = c5, bold = true })
  vim.api.nvim_set_hl(0, "@variable", { fg = json.foreground })
  vim.api.nvim_set_hl(0, "@variable.builtin", { fg = c1 })
  vim.api.nvim_set_hl(0, "@string", { fg = c2 })
  vim.api.nvim_set_hl(0, "@number", { fg = c3 })
  vim.api.nvim_set_hl(0, "@boolean", { fg = c3, bold = true })
  vim.api.nvim_set_hl(0, "@function", { fg = c4 })
  vim.api.nvim_set_hl(0, "@function.builtin", { fg = c4 })

  -- HackTheBox Notes Custom Layout Groups
  vim.api.nvim_set_hl(0, "RenderMarkdownH1", { fg = c1, bold = true })
  vim.api.nvim_set_hl(0, "RenderMarkdownH2", { fg = c2, bold = true })
  vim.api.nvim_set_hl(0, "RenderMarkdownH3", { fg = c3, bold = true })
  vim.api.nvim_set_hl(0, "RenderMarkdownBullet", { fg = c6, bold = true })
  vim.api.nvim_set_hl(0, "RenderMarkdownCode", { bg = json.color0 })
  vim.api.nvim_set_hl(0, "RenderMarkdownCodeInline", { fg = c4, bg = json.color0 })
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

-- DYNAMIC FONT & SCALE ADJUSTMENT (Ctrl + / Ctrl - / Ctrl 0)
local function adjust_font_size(delta)
  if vim.g.neovide then
    local current_scale = vim.g.neovide_scale_factor or 1.0
    if delta == 0 then
      vim.g.neovide_scale_factor = 1.0
    else
      local new_scale = math.max(0.5, math.min(2.5, current_scale + (delta * 0.1)))
      vim.g.neovide_scale_factor = new_scale
    end
  else
    local current_font = vim.o.guifont
    if current_font == "" or not current_font then
      current_font = "monospace:h12"
    end
    local font_name, current_size = current_font:match("^(.-):h(%d+)$")
    if font_name and current_size then
      local new_size = delta == 0 and 12 or math.max(6, math.min(48, tonumber(current_size) + delta))
      vim.o.guifont = font_name .. ":h" .. tostring(new_size)
    end
  end
end

local zoom_modes = { "n", "i", "v", "t" }
vim.keymap.set(zoom_modes, "<C-=>", function() adjust_font_size(1) end, { desc = "Increase Font Size" })
vim.keymap.set(zoom_modes, "<C-+>", function() adjust_font_size(1) end, { desc = "Increase Font Size" })
vim.keymap.set(zoom_modes, "<C-kPlus>", function() adjust_font_size(1) end, { desc = "Increase Font Size" })
vim.keymap.set(zoom_modes, "<C-->", function() adjust_font_size(-1) end, { desc = "Decrease Font Size" })
vim.keymap.set(zoom_modes, "<C-kMinus>", function() adjust_font_size(-1) end, { desc = "Decrease Font Size" })
vim.keymap.set(zoom_modes, "<C-0>", function() adjust_font_size(0) end, { desc = "Reset Font Size" })

-- PLUGIN CONFIGURATION
require("lazy").setup({
  { import = "plugins" },
})


