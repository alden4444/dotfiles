return {
  -- AUTO PAIRS (VS Code style bracket & quote auto-closing, enter expansion)
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {
      check_ts = true, -- Enable Treesitter integration to prevent invalid pairing in strings/comments
      ts_config = {
        lua = { "string" },
        javascript = { "template_string" },
      },
      disable_filetype = { "TelescopePrompt", "spectre_panel" },
      enable_moveright = true, -- Overtype closing brackets/quotes (step over when typing matching closing char)
      enable_afterquote = true, -- Auto pair quotes
      enable_check_bracket_line = true, -- Check bracket on line
      enable_bracket_in_quote = true,
      break_undo = true, -- Undo breaks on pair insertion
      map_cr = true, -- Map <CR> so pressing Enter inside {} / () / [] indents & moves closing bracket 2 lines down
      map_bs = true, -- Map <BS> so Backspace inside empty pair (|) deletes both characters
      map_c_h = false,
      map_c_w = false,
    },
    config = function(_, opts)
      local npairs = require("nvim-autopairs")
      npairs.setup(opts)

      local Rule = require("nvim-autopairs.rule")
      local cond = require("nvim-autopairs.conds")

      -- VS Code style space expansion inside pairs: ( | ) and backspacing empty spaces
      npairs.add_rules({
        Rule(" ", " ")
          :with_pair(function(opts_rule)
            local pair = opts_rule.line:sub(opts_rule.col - 1, opts_rule.col)
            return vim.tbl_contains({ "()", "[]", "{}" }, pair)
          end)
          :with_move(cond.none())
          :with_cr(cond.none())
          :with_del(function(opts_rule)
            local col = vim.api.nvim_win_get_cursor(0)[2]
            local context = opts_rule.line:sub(col - 1, col + 2)
            return vim.tbl_contains({ "(  )", "[  ]", "{  }" }, context)
          end),
      })
    end,
  },

  -- AUTO TAG (VS Code style HTML/XML/JSX/TSX tag auto-closing and auto-renaming)
  {
    "windwp/nvim-ts-autotag",
    event = { "BufReadPre", "BufNewFile" },
    opts = {},
  },
}
