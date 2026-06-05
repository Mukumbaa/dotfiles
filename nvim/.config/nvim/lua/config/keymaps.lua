-- Keymaps

-- Leader
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"


vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>") --open file explorer
vim.keymap.set("n", "<Tab>", ":bnext<CR>") -- go to next buffer
vim.keymap.set("n", "<S-Tab>", ":bprevious<CR>") -- go to prev buffer
vim.keymap.set({ "n", "v" }, "gl", "$") -- go to end of line
vim.keymap.set({ "n", "v" }, "gh", "^") -- go to start of line
vim.keymap.set("n", "ge", "G") -- go to end of file
vim.keymap.set("n", "<leader>a", "ggVG") -- select all file
vim.keymap.set("n", "<C-c>", "gcc", { remap = true, silent = true }) -- comment line under cursor
vim.keymap.set("v", "<C-c>", "gcc", { remap = true, silent = true }) -- comment block of line in V mode
vim.keymap.set("n", "<leader>w", "<cmd>update<CR>") -- save file
vim.keymap.set("n", "<leader>f", ":lua require('fzf-lua').files()<CR>") --search cwd
vim.keymap.set("n", "<leader>D", ":lua require('fzf-lua').diagnostics_document()<CR>") --diagnostics_document
vim.keymap.set("n", "<leader>Fh", ":lua require('fzf-lua').files({ cwd = '~/' })<CR>") --search home
vim.keymap.set("n", "<leader>Fc", ":lua require('fzf-lua').files({ cwd = '~/.config/nvim' })<CR>") --search .config
vim.keymap.set("n", "<leader>Fl", ":lua require('fzf-lua').files({ cwd = '~/.local/src' })<CR>") --search .local/src
vim.keymap.set("n", "<leader>Ff", ":lua require('fzf-lua').files({ cwd = '..' })<CR>") --search above
vim.keymap.set("n", "<leader>Fr", ":lua require('fzf-lua').resume()<CR>") --last search
vim.keymap.set("n", "<leader>g", ":lua require('fzf-lua').grep()<CR>") --grep
vim.keymap.set("n", "<leader>G", ":lua require('fzf-lua').grep_cword()<CR>") --grep word under cursor
vim.keymap.set("n", "<leader>FF", ":lua require('fzf-lua').files({ cwd = vim.fn.expand('%:p:h') })<CR>", { silent = true, desc = "Fzf search in file directory" })

vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]], { desc = "Delete without yanking" }) -- delete without yanking
vim.keymap.set("n", "<leader>u", ":nohl<CR>", { desc = "Clear search highlighting", silent = true }) -- clear search highlighting
vim.keymap.set("v", "<", "<gv", { desc = "Unindent and keep selection" }) -- indent
vim.keymap.set("v", ">", ">gv", { desc = "Indent and keep selection" }) -- indent
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
{ desc = "Replace word cursor is on globally" })
vim.keymap.set("n", "<leader>X", "<cmd>!chmod +x %<CR>", { silent = true, desc = "makes file executable" }) -- make file executable

vim.keymap.set("n", "<A-j>", "<cmd>m .+1<CR>==", { desc = "move line under cursor down" }) -- move line under cursor down 
vim.keymap.set("n", "<A-k>", "<cmd>m .-2<CR>==", { desc = "move line under cursor up" }) -- move line under cursor up

vim.keymap.set("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "move block of line down" }) -- move block of line down
vim.keymap.set("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "move block of line up" }) -- move block of line up

vim.keymap.set("i", "<A-j>", "<Esc><cmd>m .+1<CR>==gi", { desc = "move line under cursor down (Insert)" })
vim.keymap.set("i", "<A-k>", "<Esc><cmd>m .-2<CR>==gi", { desc = "move line under cursor up (Insert)" })


vim.keymap.set("n", "<A-J>", "<cmd>t .<CR>", { desc = "copy line under cursor down" }) -- copy line under cursor down
vim.keymap.set("n", "<A-K>", "<cmd>t .-1<CR>", { desc = "copy line under cursor up" })-- copy line under cursor up

vim.keymap.set("v", "<A-J>", ":t '><CR>'[V']", { desc = "copy block of line down" }) -- copy block of line down
vim.keymap.set("v", "<A-K>", ":t '<-1<CR>'[V']", { desc = "copy block of line up" })-- copy block of line up

-- local tp = require("config.teleport")
vim.keymap.set("n", "<CR>", require("config.teleport").teleport)
