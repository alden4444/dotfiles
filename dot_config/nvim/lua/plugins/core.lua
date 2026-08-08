return {
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
      vim.keymap.set('n', '<leader>cd', ":cd ", { desc = "Change Directory / Open Folder" })
      vim.keymap.set('n', '<leader>fd', function()
        builtin.find_files({
          prompt_title = "Open Folder",
          find_command = { "find", ".", "-maxdepth", "3", "-type", "d", "-not", "-path", "*/.*" },
          attach_mappings = function(prompt_bufnr)
            local actions = require("telescope.actions")
            local action_state = require("telescope.actions.state")
            actions.select_default:replace(function()
              actions.close(prompt_bufnr)
              local selection = action_state.get_selected_entry()
              if selection then
                vim.cmd("cd " .. selection[1])
                vim.cmd("Neotree show")
              end
            end)
            return true
          end,
        })
      end, { desc = "Find & Open Folder" })
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
}

