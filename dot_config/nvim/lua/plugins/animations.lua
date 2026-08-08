return {
  -- Mirrors: editor.cursorBlinking "smooth" + cursorSmoothCaretAnimation "on"
  {
    "gen740/SmoothCursor.nvim",
    event = "VeryLazy",
    config = function()
      require("smoothcursor").setup({
        type = "exp",         -- exponential easing = closest to VSCode's smooth caret feel
        cursor = "▏",         -- thin bar, matches VSCode's default caret shape
        texthl = "SmoothCursor",
        linehl = nil,         -- set e.g. "CursorLine" if you also want line highlight
        fancy = {
          enable = false,     -- true adds a trailing "comet" effect, off = closer to VSCode
        },
        speed = 30,           -- higher = faster catch-up (VSCode's animation is fairly quick)
        intervals = 30,       -- lower = smoother/more frames
        priority = 10,
        autostart = true,
        flyin_effect = nil,
        threshold = 3,        -- min distance before animating (avoids jitter on adjacent chars)
        disable_float_win = true,
        enabled_filetypes = nil,
        disabled_filetypes = nil,
      })
    end,
  },

  -- Mirrors: editor.smoothScrolling + workbench.list.smoothScrolling
  {
    "karb94/neoscroll.nvim",
    event = "VeryLazy",
    config = function()
      require("neoscroll").setup({
        mappings = {
          "<C-u>", "<C-d>", "<C-b>", "<C-f>",
          "<C-y>", "<C-e>",
          "zt", "zz", "zb",
        },
        hide_cursor = true,       -- hides cursor during scroll, like VSCode's animated viewport
        stop_eof = true,
        respect_scrolloff = false,
        cursor_scrolls_alone = true,
        easing_function = "quadratic", -- matches VSCode's smooth scroll easing curve
        pre_hook = nil,
        post_hook = nil,
        performance_mode = false,
      })

      -- covers popup/list scrolling (quickfix, completion menus) ~ workbench.list.smoothScrolling
      local neoscroll = require("neoscroll")
      local keymap = {
        ["<C-d>"] = function() neoscroll.ctrl_d({ duration = 250 }) end,
        ["<C-u>"] = function() neoscroll.ctrl_u({ duration = 250 }) end,
      }
      local modes = { "n", "v", "x" }
      for key, func in pairs(keymap) do
        vim.keymap.set(modes, key, func)
      end
    end,
  },
}
