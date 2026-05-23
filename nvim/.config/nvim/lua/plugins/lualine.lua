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

    -- local diff = {
    --   "diff",
    --   colored = true,
    --   symbols = { added = " ", modified = " ", removed = " " },
    -- }

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
        -- lualine_x = { diff, "fileformat", "filetype" },
        -- lualine_x = { "location" },
        lualine_y = { progress },
        lualine_z = {{"datetime", style = "%H:%M"}}
      },
      extensions = { "nvim-tree" },
    }
  end,
}
