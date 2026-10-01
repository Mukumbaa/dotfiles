return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  event = "VeryLazy",
  opts = function()
    local diagnostics = {
      "diagnostics",
      sources = { "nvim_diagnostic" },
      sections = { "error", "warn" },
      symbols = { error = " ", warn = " " },
      colored = true,
      update_in_insert = false,
      always_visible = true,
      cond = function()
        return vim.bo.filetype ~= "markdown"
      end,
    }


    local mode = {
      "mode",
      fmt = function(str)
        return "-- " .. str .. " --"
      end,
    }

    local branch = {
      "branch",
      icon = "",
    }

    local progress = function()
      local current_line = vim.fn.line(".")
      local total_lines = vim.fn.line("$")
      -- local chars = { "", "", "" }
      local line_ratio = current_line / total_lines
      -- local index = math.ceil(line_ratio * #chars)
      -- return chars[index] .. " " .. math.floor(line_ratio * 100) .. "%%"
      return math.floor(line_ratio * 100) .. "%%"
    end


    local lsp_status = function()
      local buf_clients = vim.lsp.get_clients({ bufnr = 0 })
      if #buf_clients == 0 then
        return "󰅛 No LSP"
      end

      local client_names = {}
      local is_loading = false

      for _, client in ipairs(buf_clients) do
        table.insert(client_names, client.name)

        if vim.lsp.status then
          local progress_msgs = vim.lsp.status()
          if progress_msgs and progress_msgs ~= "" then
            is_loading = true
          end
        end
      end
      local names_str = table.concat(client_names, ", ")

      if is_loading then
        return "󰔟 " .. names_str .. " (Loading...)"
      else
        return " " .. names_str
      end
    end







    return {
      options = {
        icons_enabled = true,
        theme = "auto",
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },
        disabled_filetypes = { "alpha", "dashboard" },
        always_divide_middle = true,
      },
      sections = {
        lualine_a = { branch },
        lualine_b = { mode },
        lualine_c = { diagnostics, "filename" },
        lualine_x = {
          lsp_status,
          "encoding",
          "fileformat",
          "filetype",
        },
        lualine_y = { progress },
        lualine_z = {{"datetime", style = "%H:%M"}}
      },
      extensions = { "nvim-tree" },
    }
  end,
}
