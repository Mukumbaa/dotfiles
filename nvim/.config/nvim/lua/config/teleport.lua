local M = {}

-- set up highlight groups linked to the current theme
-- link "TeleportJumpLabel" to the search highlight (usually yellow/orange background)
vim.api.nvim_set_hl(0, "TeleportJumpLabel", { link = "Search", bold = true })

-- link "TeleportJumpMatch" to the current search match highlight (often blue/green)
vim.api.nvim_set_hl(0, "TeleportJumpMatch", { link = "IncSearch", bold = true })

-- link "TeleportJumpDimmed" to comment highlight to fade out text
vim.api.nvim_set_hl(0, "TeleportJumpDimmed", { link = "Comment" })

function M.teleport()
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_get_current_buf()
  local ns_id = vim.api.nvim_create_namespace("Teleport-effects")

  -- clean up all highlights and redraw
  local function cleanup()
    vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)
    vim.cmd("redraw")
  end

  -- get visible lines in the current window
  local start_line = vim.fn.line("w0") - 1
  local end_line = vim.fn.line("w$")
  local lines = vim.api.nvim_buf_get_lines(buf, start_line, end_line, false)

  -- generate all two‑letter labels from aa to zz
  -- local chars = "abcdefghijklmnopqrstuvwxyz"
  -- local labels_list = {}
  -- for i = 1, #chars do
  --   for j = 1, #chars do
  --     table.insert(labels_list, chars:sub(i, i) .. chars:sub(j, j))
  --   end
  -- end
  local lower = "abcdefghijklmnopqrstuvwxyz"
  local extras = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  local labels_list = {}

  -- generate all purely lowercase two‑letter combinations
  for i = 1, #lower do
    for j = 1, #lower do
      table.insert(labels_list, lower:sub(i, i) .. lower:sub(j, j))
    end
  end

  -- generate mixed combinations using numbers and uppercase letters
  -- concatenate all characters for the remaining combinations
  local all_chars = lower .. extras
  for i = 1, #all_chars do
    for j = 1, #all_chars do
      local lbl = all_chars:sub(i, i) .. all_chars:sub(j, j)

      -- insert label only if it is not two lowercase letters 
      -- (those were already generated in the first loop)
      local first_is_lower = lower:find(lbl:sub(1, 1), 1, true) ~= nil
      local second_is_lower = lower:find(lbl:sub(2, 2), 1, true) ~= nil

      if not (first_is_lower and second_is_lower) then
        table.insert(labels_list, lbl)
      end
    end
  end
  -- collect every word (alphanumeric sequence) and assign a label
  local all_targets = {}
  local label_idx = 1
  for r_idx, line in ipairs(lines) do
    local abs_row = start_line + r_idx - 1
    for col in line:gmatch("()([%w_]+)") do
      if label_idx <= #labels_list then
        local lbl = labels_list[label_idx]
        all_targets[lbl] = { row = abs_row, col = col - 1 }
        label_idx = label_idx + 1
      end
    end
  end

  -- draw labels on screen (filtered by first character if provided)
  local function draw_ui(filter_char)
    vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)

    -- dim the entire visible area with an overlay
    for r_idx = start_line, end_line - 1 do
      local line_len = string.len(lines[r_idx - start_line + 1] or "")
      vim.api.nvim_buf_set_extmark(buf, ns_id, r_idx, 0, {
        end_col = line_len,
        hl_group = "TeleportJumpDimmed",
        hl_eol = true,
      })
    end

    -- place virtual text labels over words
    for lbl, pos in pairs(all_targets) do
      if not filter_char then
        vim.api.nvim_buf_set_extmark(buf, ns_id, pos.row, pos.col, {
          virt_text = { { lbl, "TeleportJumpLabel" } },
          virt_text_pos = "overlay",
        })
      elseif lbl:sub(1, 1) == filter_char then
        vim.api.nvim_buf_set_extmark(buf, ns_id, pos.row, pos.col, {
          virt_text = { { lbl, "TeleportJumpMatch" } },
          virt_text_pos = "overlay",
        })
      end
    end
    vim.cmd("redraw")
  end

  -- show all labels at once
  draw_ui(nil)

  -- read first character of the label
  local char1 = vim.fn.getcharstr()
  if char1 == "\27" or char1 == "" then return cleanup() end

  -- check if any label starts with that character
  local has_matches = false
  for lbl, _ in pairs(all_targets) do
    if lbl:sub(1, 1) == char1 then
      has_matches = true
      break
    end
  end

  -- no matches → abort
  if not has_matches then
    return cleanup()
  end

  -- filter the display to show only matching labels
  draw_ui(char1)

  -- read second character
  local char2 = vim.fn.getcharstr()
  if char2 == "\27" or char2 == "" then return cleanup() end

  local final_label = char1 .. char2
  local target = all_targets[final_label]

  -- clean up and jump to the target position
  cleanup()
  if target then
    vim.api.nvim_win_set_cursor(win, { target.row + 1, target.col })
  else
    -- invalid label combination: just show a message and do nothing
    print("Label inesistente")
  end
end

return M
