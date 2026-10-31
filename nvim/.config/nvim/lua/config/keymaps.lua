-- Leader keys
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- General
vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { desc = "Toggle file explorer" })
vim.keymap.set("n", "<Tab>", ":bnext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<S-Tab>", ":bprevious<CR>", { desc = "Previous buffer" })
vim.keymap.set({ "n", "v" }, "gl", "$", { desc = "Goto end of line" })
vim.keymap.set({ "n", "v" }, "gh", "^", { desc = "Goto start of line" })
vim.keymap.set("n", "ge", "G", { desc = "Goto end of file" })
vim.keymap.set("n", "<leader>a", "ggVG", { desc = "Select entire file" })
vim.keymap.set("n", "<C-c>", "gcc", { remap = true, silent = true, desc = "Comment line" })
vim.keymap.set("v", "<C-c>", "gc", { remap = true, silent = true, desc = "Comment selection" })
vim.keymap.set("n", "<leader>w", "<cmd>update<CR>", { desc = "Save file" })

-- FZF-Lua
local fzf = function(fn, opts)
  return function()
    require("fzf-lua")[fn](opts)
  end
end

vim.keymap.set("n", "<leader>f", fzf("files"), { desc = "Find files" })
vim.keymap.set("n", "<leader>D", fzf("diagnostics_document"), { desc = "Document diagnostics" })
vim.keymap.set("n", "<leader>Fh", fzf("files", { cwd = "~/" }), { desc = "Find files in home" })
vim.keymap.set("n", "<leader>Fc", fzf("files", { cwd = "~/.config/nvim" }), { desc = "Find files in config" })
vim.keymap.set("n", "<leader>Fl", fzf("files", { cwd = "~/.local/src" }), { desc = "Find files in local source" })
vim.keymap.set("n", "<leader>Ff", fzf("files", { cwd = ".." }), { desc = "Find files in parent directory" })
vim.keymap.set("n", "<leader>Fr", fzf("resume"), { desc = "Resume last search" })
vim.keymap.set("n", "<leader>g", fzf("grep"), { desc = "Live grep" })
vim.keymap.set("n", "<leader>G", fzf("grep_cword"), { desc = "Grep word under cursor" })
vim.keymap.set("n", "<leader>FF", function()
  require("fzf-lua").files({ cwd = vim.fn.expand("%:p:h") })
end, { desc = "Find files in file directory" })

-- Editing
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]], { desc = "Delete without yanking" })
vim.keymap.set("n", "<leader>x", ":bw<CR>", { silent = true, desc = "Close current buffer" })
vim.keymap.set("v", "<", "<gv", { desc = "Unindent selection" })
vim.keymap.set("v", ">", ">gv", { desc = "Indent selection" })
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = "Replace word under cursor" })
vim.keymap.set("n", "<leader>X", "<cmd>!chmod +x %<CR>", { silent = true, desc = "Make file executable" })

-- Move lines
vim.keymap.set("n", "<A-j>", "<cmd>m .+1<CR>==", { desc = "Move line down" })
vim.keymap.set("n", "<A-k>", "<cmd>m .-2<CR>==", { desc = "Move line up" })
vim.keymap.set("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
vim.keymap.set("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })
vim.keymap.set("i", "<A-j>", "<Esc><cmd>m .+1<CR>==gi", { desc = "Move line down" })
vim.keymap.set("i", "<A-k>", "<Esc><cmd>m .-2<CR>==gi", { desc = "Move line up" })

-- Duplicate lines
vim.keymap.set("n", "<A-J>", "<cmd>t .<CR>", { desc = "Duplicate line down" })
vim.keymap.set("n", "<A-K>", "<cmd>t .-1<CR>", { desc = "Duplicate line up" })
vim.keymap.set("v", "<A-J>", ":t '><CR>'[V']", { desc = "Duplicate selection down" })
vim.keymap.set("v", "<A-K>", ":t '<-1<CR>'[V']", { desc = "Duplicate selection up" })

-- Navigation
vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true, desc = "Move down display line" })
vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true, desc = "Move up display line" })
vim.keymap.set("n", "<CR>", require("config.teleport").teleport, { desc = "Teleport jump" })

-- Indent blocks
vim.keymap.set("v", "<Tab>", ">gv", { noremap = true, silent = true, desc = "Indent selection" })
vim.keymap.set("v", "<S-Tab>", "<gv", { noremap = true, silent = true, desc = "Unindent selection" })

-- Text alignment
vim.keymap.set("v", "<leader>t", function()
  local line_start = vim.fn.line("v")
  local line_end = vim.fn.line(".")

  if line_start > line_end then
    line_start, line_end = line_end, line_start
  end

  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)

  vim.schedule(function()
    vim.cmd("redraw")
    local char = vim.fn.input("Character to align: ")
    if not char or char == "" then return end

    local lines = vim.api.nvim_buf_get_lines(0, line_start - 1, line_end, false)
    local max_len = 0
    local parsed = {}

    for _, line in ipairs(lines) do
      local idx = line:match(".*()" .. vim.pesc(char))
      if idx then
        local left = line:sub(1, idx - 1):gsub("%s+$", "")
        local right = line:sub(idx)
        if #left > max_len then
          max_len = #left
        end
        table.insert(parsed, { left = left, right = right })
      else
        table.insert(parsed, { raw = line })
      end
    end

    local new_lines = {}
    for _, item in ipairs(parsed) do
      if item.raw then
        table.insert(new_lines, item.raw)
      else
        local padding = string.rep(" ", max_len - #item.left + 1)
        table.insert(new_lines, item.left .. padding .. item.right)
      end
    end

    vim.api.nvim_buf_set_lines(0, line_start - 1, line_end, false, new_lines)
  end)
end, { desc = "Align selection by character" })

-- UI and search cleanup
vim.keymap.set("n", "<Esc>", function()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local config = vim.api.nvim_win_get_config(win)
    if config.relative ~= "" then
      vim.api.nvim_win_close(win, true)
    end
  end
  vim.cmd("nohlsearch")
end, { desc = "Close floating windows and clear search highlight" })

-- Seleziona il prossimo argomento/parametro tra parentesi in tutto il file (Zero plugin)
local function select_param_file(direction)
  local mode = vim.api.nvim_get_mode().mode
  local buf = 0

  -- Se siamo già in Visual Mode, usciamo per reimpostare la selezione pulita
  if mode:match("^[vV\22]") then
    vim.cmd("normal! \27")
  end

  local cur_pos = vim.api.nvim_win_get_cursor(0)
  local cur_row, cur_col = cur_pos[1], cur_pos[2] + 1

  -- Funzioni di conversione riga/colonna <-> offset continuo
  local function pos_to_offset(r, c)
    local lines = vim.api.nvim_buf_get_lines(buf, 0, r - 1, false)
    local off = 0
    for _, l in ipairs(lines) do
      off = off + #l + 1 -- +1 per il newline
    end
    return off + c
  end

  local function offset_to_pos(target_off)
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local acc = 0
    for idx, l in ipairs(lines) do
      local next_acc = acc + #l + 1
      if target_off <= next_acc then
        return idx, math.min(#l, math.max(1, target_off - acc))
      end
      acc = next_acc
    end
    return #lines, #lines[#lines]
  end

  local all_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local text = table.concat(all_lines, "\n")
  local current_offset = pos_to_offset(cur_row, cur_col)

  local all_params = {}
  local p_stack = {}
  local in_string = false
  local str_char = ""
  local escaped = false

  -- Riconosce tutte le parentesi tonde e suddivide gli argomenti per virgola
  for i = 1, #text do
    local ch = text:sub(i, i)

    if in_string then
      if escaped then
        escaped = false
      elseif ch == "\\" then
        escaped = true
      elseif ch == str_char then
        in_string = false
      end
    else
      if ch == '"' or ch == "'" or ch == "`" then
        in_string = true
        str_char = ch
      elseif ch == "(" then
        table.insert(p_stack, { depth = 0, start_p = i + 1 })
      elseif ch == "{" or ch == "[" then
        if #p_stack > 0 then
          p_stack[#p_stack].depth = p_stack[#p_stack].depth + 1
        end
      elseif ch == "}" or ch == "]" then
        if #p_stack > 0 and p_stack[#p_stack].depth > 0 then
          p_stack[#p_stack].depth = p_stack[#p_stack].depth - 1
        end
      elseif ch == "," and #p_stack > 0 then
        local top = p_stack[#p_stack]
        if top.depth == 0 then
          table.insert(all_params, { s = top.start_p, e = i - 1 })
          top.start_p = i + 1
        end
      elseif ch == ")" and #p_stack > 0 then
        local top = table.remove(p_stack)
        if top.depth == 0 then
          table.insert(all_params, { s = top.start_p, e = i - 1 })
        end
      end
    end
  end

  -- Pulisce spazi e a capo iniziali/finali di ogni elemento
  local valid_params = {}
  for _, p in ipairs(all_params) do
    if p.s <= p.e then
      local sub = text:sub(p.s, p.e)
      local l_pad = sub:match("^%s*") or ""
      local r_pad = sub:match("%s*$") or ""
      local real_s = p.s + #l_pad
      local real_e = p.e - #r_pad
      if real_s <= real_e then
        table.insert(valid_params, { s = real_s, e = real_e })
      end
    end
  end

  table.sort(valid_params, function(a, b) return a.s < b.s end)

  if #valid_params == 0 then
    return vim.notify("No parenthesized arguments found in buffer", vim.log.levels.WARN)
  end

  -- Trova l'argomento successivo o precedente
  local target = nil
  if direction == 1 then
    for _, p in ipairs(valid_params) do
      if p.s > current_offset then
        target = p
        break
      end
    end
    target = target or valid_params[1] -- Ritorna all'inizio del file
  else
    for i = #valid_params, 1, -1 do
      local p = valid_params[i]
      if p.e < current_offset then
        target = p
        break
      end
    end
    target = target or valid_params[#valid_params] -- Ritorna alla fine del file
  end

  local s_r, s_c = offset_to_pos(target.s)
  local e_r, e_c = offset_to_pos(target.e)

  -- Applica la selezione visiva pulita
  vim.api.nvim_win_set_cursor(0, { s_r, s_c - 1 })
  vim.cmd("normal! v")
  vim.api.nvim_win_set_cursor(0, { e_r, e_c - 1 })
end

-- Keymap in Normal e Visual Mode
vim.keymap.set({ "n", "v" }, "<leader>l", function() select_param_file(1) end, { desc = "Select next argument in file" })
vim.keymap.set({ "n", "v" }, "<leader>h", function() select_param_file(-1) end, { desc = "Select previous argument in file" })
