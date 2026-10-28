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
vim.keymap.set("v", "<C-c>", "gc", { remap = true, silent = true }) -- comment block of line in V mode
vim.keymap.set("n", "<leader>w", "<cmd>update<CR>") -- save file

local fzf = function(fn, opts)
  return function()
    require("fzf-lua")[fn](opts)
  end
end

vim.keymap.set("n", "<leader>f",  fzf("files"), { desc = "FZF Cerca file (CWD)" })
vim.keymap.set("n", "<leader>D",  fzf("diagnostics_document"), { desc = "FZF Diagnostiche documento" })
vim.keymap.set("n", "<leader>Fh", fzf("files", { cwd = "~/" }), { desc = "FZF Cerca in ~/" })
vim.keymap.set("n", "<leader>Fc", fzf("files", { cwd = "~/.config/nvim" }), { desc = "FZF Cerca in ~/.config/nvim" })
vim.keymap.set("n", "<leader>Fl", fzf("files", { cwd = "~/.local/src" }), { desc = "FZF Cerca in ~/.local/src" })
vim.keymap.set("n", "<leader>Ff", fzf("files", { cwd = ".." }), { desc = "FZF Cerca nella cartella superiore" })
vim.keymap.set("n", "<leader>Fr", fzf("resume"), { desc = "FZF Riprendi ultima ricerca" })
vim.keymap.set("n", "<leader>g",  fzf("grep"), { desc = "FZF Live Grep" })
vim.keymap.set("n", "<leader>G",  fzf("grep_cword"), { desc = "FZF Cerca parola sotto cursore" })

vim.keymap.set("n", "<leader>FF", function()
  require("fzf-lua").files({ cwd = vim.fn.expand("%:p:h") })
end, { desc = "FZF Cerca nella cartella del file corrente" })


vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]], { desc = "Delete without yanking" }) -- delete without yanking
vim.keymap.set("n", "<leader>x", ":nohl<CR>", { desc = "Clear search highlighting", silent = true }) -- clear search highlighting
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

vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
-- local tp = require("config.teleport")
vim.keymap.set("n", "<CR>", require("config.teleport").teleport)

-- Adds tab on all selected line
vim.keymap.set('v', '<Tab>', '>gv', { noremap = true, silent = true })

-- Subs tab on all selected line
vim.keymap.set('v', '<S-Tab>', '<gv', { noremap = true, silent = true })

-- Allinea un carattere a scelta nella selezione visuale usando 'column'
vim.keymap.set('v', '<leader>t', function()
  -- 1. Salva i numeri di riga della selezione visuale
  local line_start = vim.fn.line("v")
  local line_end = vim.fn.line(".")

  if line_start > line_end then
    line_start, line_end = line_end, line_start
  end

  -- Esce dalla modalità visuale
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', false)

  vim.schedule(function()
    vim.cmd('redraw')
    local char = vim.fn.input('Carattere da allineare: ')
    if not char or char == '' then return end

    -- Recupera le righe selezionate
    local lines = vim.api.nvim_buf_get_lines(0, line_start - 1, line_end, false)

    -- Calcola la lunghezza massima del testo prima del carattere di separazione
    local max_len = 0
    local parsed = {}

    for _, line in ipairs(lines) do
      -- Trova l'ultima occorrenza del carattere (utilissimo per i backslash a fine riga)
      local idx = line:match(".*()" .. vim.pesc(char))
      if idx then
        local left = line:sub(1, idx - 1):gsub("%s+$", "") -- Rimuove gli spazi finali prima del carattere
        local right = line:sub(idx)
        if #left > max_len then
          max_len = #left
        end
        table.insert(parsed, { left = left, right = right })
      else
        table.insert(parsed, { raw = line })
      end
    end

    -- Ricostruisce le righe allineate con la spaziatura minima necessaria
    local new_lines = {}
    for _, item in ipairs(parsed) do
      if item.raw then
        table.insert(new_lines, item.raw)
      else
        -- Aggiunge il carattere di separazione separato da uno spazio dopo la parte sinistra
        local padding = string.rep(" ", max_len - #item.left + 1)
        table.insert(new_lines, item.left .. padding .. item.right)
      end
    end

    -- Aggiorna il buffer
    vim.api.nvim_buf_set_lines(0, line_start - 1, line_end, false, new_lines)
  end)
end, { desc = "Align selected text by chosen character" })
-- Chiudi le finestre fluttuanti (hover LSP, diagnostiche, ecc.) e rimuovi l'evidenziazione della ricerca premendo Esc
vim.keymap.set("n", "<Esc>", function()
  -- Chiude eventuali finestre fluttuanti aperte
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local config = vim.api.nvim_win_get_config(win)
    if config.relative ~= "" then -- è una finestra fluttuante
      vim.api.nvim_win_close(win, true)
    end
  end
  -- Pulisce anche l'highlight della ricerca (sostituisce :nohl)
  vim.cmd("nohlsearch")
end, { desc = "Chiudi finestre fluttuanti e rimuovi highlight ricerca" })
