return {
  -- WEB DEVICONS FOR FILE TYPES
  { "nvim-tree/nvim-web-devicons", lazy = true },
  { "MunifTanjim/nui.nvim", lazy = true },

  -- VIBRANT COLOR SCHEMES (Fixes monochrome editor issue)
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = "mocha",
      term_colors = true,
      integrations = {
        neotree = true,
        telescope = true,
        treesitter = true,
        render_markdown = true,
      },
    },
  },
  {
    "folke/tokyonight.nvim",
    lazy = true,
    opts = { style = "night" },
  },

  -- VS CODE STYLE FILE EXPLORER (LEFT PANEL)
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    keys = {
      { "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Toggle File Explorer" },
      { "<C-n>", "<cmd>Neotree toggle<cr>", desc = "Toggle File Explorer" },
    },
    opts = {
      close_if_last_window = true,
      popup_border_style = "rounded",
      enable_git_status = true,
      enable_diagnostics = true,
      filesystem = {
        hijack_netrw_behavior = "open_default",
        bind_to_cwd = true,
        filtered_items = {
          visible = true,
          hide_dotfiles = false,
          hide_gitignored = false,
        },
        follow_current_file = { enabled = true },
        use_libuv_file_watcher = true,
      },
      default_component_configs = {
        indent = {
          with_expanders = true,
          expander_closed = "",
          expander_opened = "",
        },
        icon = {
          folder_closed = "",
          folder_open = "",
          folder_empty = "󰜌",
          default = "󰈙",
        },
      },
      window = {
        position = "left",
        width = 30,
      },
    },
  },


  -- ANTIGRAVITY AI AGENT (RIGHT PANEL TERMINAL)
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    opts = {
      size = function(term)
        if term.direction == "horizontal" then
          return 15
        elseif term.direction == "vertical" then
          return math.floor(vim.o.columns * 0.35)
        end
      end,
      open_mapping = [[<c-\>]],
      hide_numbers = true,
      shade_terminals = false,
      start_in_insert = true,
      insert_mappings = true,
      terminal_mappings = true,
      persist_size = true,
      direction = "vertical",
      close_on_exit = true,
      shell = vim.o.shell,
      float_opts = {
        border = "curved",
      },
    },
    config = function(_, opts)
      require("toggleterm").setup(opts)

      local Terminal = require("toggleterm.terminal").Terminal
      local agy_agent = Terminal:new({
        cmd = "/home/alden/.local/bin/agy",
        direction = "vertical",
        hidden = true,
        on_open = function(term)
          vim.cmd("startinsert!")
        end,
      })

      function _G.toggle_antigravity_agent()
        agy_agent:toggle()
      end

      vim.keymap.set({ "n", "t" }, "<leader>ag", "<cmd>lua _G.toggle_antigravity_agent()<CR>", { desc = "Toggle Antigravity AI Agent" })
      vim.keymap.set({ "n", "t" }, "<leader>ai", "<cmd>lua _G.toggle_antigravity_agent()<CR>", { desc = "Toggle Antigravity AI Agent" })
      vim.keymap.set({ "n", "t" }, "<C-a>", "<cmd>lua _G.toggle_antigravity_agent()<CR>", { desc = "Toggle Antigravity AI Agent" })
    end,
  },
}
