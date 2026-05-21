-- Keymaps

-- Leader
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Up, Down
vim.keymap.set('n', 'j', 'gj', { desc = 'Up', noremap = true})
vim.keymap.set('n', 'k', 'gk', { desc = 'Down', noremap = true})

vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>")                                --open file explorer
vim.keymap.set('n', '<leader>z', ":ToggleTerm<CR>")
vim.keymap.set('t', '<esc>', "<C-\\><C-n><CMD>ToggleTerm exit<CR>")
vim.keymap.set("n", "<Tab>", ":bnext<CR>") -- go to next buffer
vim.keymap.set("n", "<S-Tab>", ":bprevious<CR>") -- go to prev buffer
vim.keymap.set("n", "gl", "$")
vim.keymap.set("n", "ge", "G")
vim.keymap.set("n", "gh", "^")
vim.keymap.set("n", "<leader>a", "ggVG")
vim.keymap.set("n", "<C-c>", "gcc", { remap = true, silent = true })
vim.keymap.set("v", "<C-c>", "gcc", { remap = true, silent = true })
vim.keymap.set("n", "<leader>u", ':silent !xdg-open "<cWORD>" &<CR>')
vim.keymap.set("n", "<leader>w", ":w<CR>")
vim.keymap.set("n", "<leader>f", ":lua require('fzf-lua').files()<CR>")                          --search cwd
vim.keymap.set("n", "<leader>D", ":lua require('fzf-lua').diagnostics_document()<CR>")           --diagnostics_document
vim.keymap.set("n", "<leader>Fh", ":lua require('fzf-lua').files({ cwd = '~/' })<CR>")           --search home
vim.keymap.set("n", "<leader>Fc", ":lua require('fzf-lua').files({ cwd = '~/.config' })<CR>")    --search .config
vim.keymap.set("n", "<leader>Fl", ":lua require('fzf-lua').files({ cwd = '~/.local/src' })<CR>") --search .local/src
vim.keymap.set("n", "<leader>Ff", ":lua require('fzf-lua').files({ cwd = '..' })<CR>")           --search above
vim.keymap.set("n", "<leader>Fr", ":lua require('fzf-lua').resume()<CR>")                        --last search
vim.keymap.set("n", "<leader>g", ":lua require('fzf-lua').grep()<CR>")                           --grep
vim.keymap.set("n", "<leader>G", ":lua require('fzf-lua').grep_cword()<CR>")                     --grep word under cursor
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]], { desc = "Delete without yanking" })
vim.keymap.set("n", "<leader>c", ":nohl<CR>", { desc = "Clear search highlighting", silent = true })
vim.keymap.set("v", "<", "<gv", { desc = "Unindent and keep selection" })
vim.keymap.set("v", ">", ">gv", { desc = "Indent and keep selection" })
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
    { desc = "Replace word cursor is on globally" })
vim.keymap.set("n", "<leader>X", "<cmd>!chmod +x %<CR>", { silent = true, desc = "makes file executable" })

-- SPOSTARE RIGHE (ALT + j / ALT + k)
-- Normal mode (singola riga)
vim.keymap.set("n", "<A-j>", "<cmd>m .+1<CR>==", { desc = "Sposta riga giù" })
vim.keymap.set("n", "<A-k>", "<cmd>m .-2<CR>==", { desc = "Sposta riga su" })

-- Visual mode (più righe). 'gv=gv' ri-seleziona e ri-indenta automaticamente
vim.keymap.set("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Sposta selezione giù" })
vim.keymap.set("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Sposta selezione su" })

-- Insert mode (ti permette di spostare la riga mentre stai scrivendo)
vim.keymap.set("i", "<A-j>", "<Esc><cmd>m .+1<CR>==gi", { desc = "Sposta riga giù (Insert)" })
vim.keymap.set("i", "<A-k>", "<Esc><cmd>m .-2<CR>==gi", { desc = "Sposta riga su (Insert)" })


-- DUPLICARE RIGHE (ALT + SHIFT + j / k) -> Neovim li legge come J e K maiuscole
-- Normal mode (singola riga)
vim.keymap.set("n", "<A-J>", "<cmd>t .<CR>", { desc = "Duplica riga giù" })
vim.keymap.set("n", "<A-K>", "<cmd>t .-1<CR>", { desc = "Duplica riga su" })

-- Visual mode (più righe). Copia in blocco sopra o sotto la selezione e MANTIENE SELEZIONATO il nuovo testo
vim.keymap.set("v", "<A-J>", ":t '><CR>'[V']", { desc = "Duplica selezione giù e seleziona" })
vim.keymap.set("v", "<A-K>", ":t '<-1<CR>'[V']", { desc = "Duplica selezione su e seleziona" })
