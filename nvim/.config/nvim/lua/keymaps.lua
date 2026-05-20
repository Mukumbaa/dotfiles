vim.g.mapleader = " "

vim.keymap.set("x", "p", [["_dP]], { desc = "Paste over selection without losing yanked text" })

vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]], { desc = "Delete without yanking" })

vim.keymap.set("i", "<C-c>", "<Esc>")
vim.keymap.set("n", "<leader>c", ":nohl<CR>", { desc = "Clear search highlighting", silent = true })

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "moves lines down in visual selection" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "moves lines up in visual selection" })

vim.keymap.set("v", "<", "<gv", { desc = "Unindent and keep selection" })
vim.keymap.set("v", ">", ">gv", { desc = "Indent and keep selection" })

vim.keymap.set("n", "J", "mzJ`z", { desc = "Join lines without moving cursor" })

vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "move down in buffer with cursor centered" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "move up in buffer with cursor centered" })

vim.keymap.set("n", "n", "nzzzv", { desc = "Next search result cursor centered" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Previous search result cursor centered" })

vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
    { desc = "Replace word cursor is on globally" })
vim.keymap.set("n", "<leader>X", "<cmd>!chmod +x %<CR>", { silent = true, desc = "makes file executable" })

vim.keymap.set("n", "<leader>re", "<cmd>restart<cr>", { desc = "Restart config :restart)" })

-- native undotree
vim.keymap.set("n", "<leader>o", function()
    vim.cmd.packadd("nvim.undotree")
    require("undotree").open()
end, { desc = "Toggle Builtin Undotree" })


vim.keymap.set("n", "<Tab>", ":bnext<CR>") -- go to next buffer
vim.keymap.set("n", "<S-Tab>", ":bprevious<CR>") -- go to prev buffer
vim.keymap.set("n", "<A-b>", ":bw<CR>") -- close one buffer
-- vim.keymap.set("n", "<leader>U", "::bufdo bd<CR>")     --close all
vim.keymap.set('n', '<leader>vs', ':vsplit<CR>:bnext<CR>')                       --ver split + open next buffer
vim.keymap.set("n", "<leader>e", ":Lexplore<CR>")                                --open file explorer
vim.keymap.set('n', '<leader>z', ":lua require('FTerm').open()<CR>")             --open term
vim.keymap.set('t', '<Esc>', '<C-\\><C-n><CMD>lua require("FTerm").close()<CR>') --preserves session
vim.keymap.set("n", "<leader>u", ':silent !xdg-open "<cWORD>" &<CR>')            --open a url under cursor
vim.g.mapleader = " "
-- ==========================================
-- 6. MAPPATURE AUTOCOMPLETAMENTO (TAB)
-- ==========================================

-- Usa Tab per scorrere in giù
vim.keymap.set("i", "<Tab>", function()
    return vim.fn.pumvisible() == 1 and "<C-n>" or "<Tab>"
end, { expr = true })

-- Usa Shift+Tab per scorrere in su
vim.keymap.set("i", "<S-Tab>", function()
    return vim.fn.pumvisible() == 1 and "<C-p>" or "<S-Tab>"
end, { expr = true })

-- Usa Invio per confermare il suggerimento
vim.keymap.set("i", "<CR>", function()
    return vim.fn.pumvisible() == 1 and "<C-y>" or "<CR>"
end, { expr = true })
-- ==========================================
-- 7. SALVATAGGIO AUTOMATICO SU ESC CON MESSAGGIO
-- ==========================================
vim.keymap.set({ "i", "n", "v" }, "<Esc>", function()
    -- Raccogliamo lo stato attuale del file
    local is_modified = vim.bo.modified     -- Il file ha modifiche non salvate?
    local is_normal = vim.bo.buftype == ""  -- È un file di testo (non un terminale o un popup fzf)?
    local has_name = vim.fn.bufname() ~= "" -- Il file ha già un nome ed esiste sul disco?
    local can_save = not vim.bo.readonly    -- Il file NON è bloccato in sola lettura?

    if is_modified and is_normal and has_name and can_save then
        -- Se tutto è ok: esce (<Esc>), salva silenziosamente (<cmd>silent! update<CR>)
        -- e stampa a schermo il nostro messaggio (<cmd>lua vim.print('✅ Salvato!')<CR>)
        return "<Esc><cmd>silent! update<CR><cmd>lua vim.print('File saved')<CR>"
    end

    -- In tutti gli altri casi (es. stiamo solo chiudendo un popup), restituisce solo Esc
    return "<Esc>"
end, { expr = true, desc = "Esc e salva se modificato con notifica" })


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


-- comment
vim.keymap.set("n", "<C-c>", "gcc", { remap = true, silent = true })
vim.keymap.set("v", "<C-c>", "gcc", { remap = true, silent = true })
vim.keymap.set("n", "<leader>f", ":lua require('fzf-lua').files()<CR>")                          --search cwd
vim.keymap.set("n", "<leader>D", ":lua require('fzf-lua').diagnostics_document()<CR>")           --diagnostics_document
vim.keymap.set("n", "<leader>Fh", ":lua require('fzf-lua').files({ cwd = '~/' })<CR>")           --search home
vim.keymap.set("n", "<leader>Fc", ":lua require('fzf-lua').files({ cwd = '~/.config' })<CR>")    --search .config
vim.keymap.set("n", "<leader>Fl", ":lua require('fzf-lua').files({ cwd = '~/.local/src' })<CR>") --search .local/src
vim.keymap.set("n", "<leader>Ff", ":lua require('fzf-lua').files({ cwd = '..' })<CR>")           --search above
vim.keymap.set("n", "<leader>Fr", ":lua require('fzf-lua').resume()<CR>")                        --last search
vim.keymap.set("n", "<leader>g", ":lua require('fzf-lua').grep()<CR>")                           --grep
vim.keymap.set("n", "<leader>G", ":lua require('fzf-lua').grep_cword()<CR>")                     --grep word under cursor
vim.keymap.set("n", "gl", "$")
vim.keymap.set("n", "ge", "G")
vim.keymap.set("n", "gh", "^")
vim.keymap.set("n", "<leader>a", "ggVG")

