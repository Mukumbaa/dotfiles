vim.pack.add({
    { src = "https://github.com/nvim-treesitter/nvim-treesitter", branch = "main" },
    { src = "https://github.com/rose-pine/neovim",                name = "rose-pine" },
    "https://github.com/nvim-lualine/lualine.nvim",
    "https://github.com/nvim-mini/mini.nvim",
    "https://github.com/rafamadriz/friendly-snippets",
    "https://github.com/neovim/nvim-lspconfig",
    "https://github.com/tpope/vim-fugitive",
    "https://github.com/folke/which-key.nvim",
    "https://github.com/numToStr/FTerm.nvim",
    "https://github.com/windwp/nvim-autopairs",
    "https://github.com/ibhagwan/fzf-lua",
    "https://github.com/nvim-tree/nvim-web-devicons",
    "https://github.com/akinsho/bufferline.nvim",
})

vim.cmd("colorscheme rose-pine")


---- mini notify ----
require("mini.notify").setup({
    -- only show messages
    content = {
        format = function(notif)
            return notif.msg
        end,
    },
})

--- mini cmdline completion ---
require("mini.cmdline").setup({
    autocorrect = { enable = false }
})

--- mini surround ---
require("mini.surround").setup()
-- Default Keymaps
-- | `sa` | Add surrounding or Direct with 'saiw' |
-- | `sd` | Delete surrounding |
-- | `sr` | Replace surrounding |
-- | `sf` | Find surrounding (right) |
-- | `sF` | Find surrounding (left) |
-- | `sh` | Highlight surrounding |
-- | `sn` | Update n_lines |
-- | `l` / `n` | as suffix for prev/next |

--- mini completions ---
require("mini.completion").setup({
    lsp_completion = {
        auto_setup = true,
    }
})

--- mini snippets ---
local MiniSnippets = require("mini.snippets")
MiniSnippets.setup({
    snippets = {
        MiniSnippets.gen_loader.from_lang(), -- loads friendly-snippets
    },
})
MiniSnippets.start_lsp_server({ match = false })

--- mini diff and fugitive ---
-- local MiniDiff = require("mini.diff")
-- MiniDiff.setup({
--     source = MiniDiff.gen_source.git({ index = false }),
-- })

vim.keymap.set("n", "<leader>gg", "<cmd>tabnew | Git | only<cr>", { desc = "Fugitive Full Page New Tab" })
vim.keymap.set("n", "<leader>gd", "<cmd>Gvdiffsplit<CR>", { desc = "Git diff split", })


require("whichkey")
require("fterm")
require("autopairs")
require("fzflua")
require("line")
