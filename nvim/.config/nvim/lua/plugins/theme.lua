local function get_active_scheme()
  local path = vim.fn.expand("~/.cache/current-theme/nvim.txt")
  local f = io.open(path, "r")
  if f then
    local scheme = f:read("*l")
    f:close()
    if scheme and scheme:match("%S") then
      return scheme:match("^%s*(.-)%s*$")
    end
  end
  return "rose-pine"
end

return {
  { "rose-pine/neovim", name = "rose-pine", lazy = false, priority = 1000 },
  { "folke/tokyonight.nvim", lazy = false, priority = 1000 },
  { "catppuccin/nvim", name = "catppuccin", lazy = false, priority = 1000 },
  { "ellisonleao/gruvbox.nvim", lazy = false, priority = 1000 },
  {
    "bluz71/vim-moonfly-colors",
    name = "moonfly",
    lazy = false,
    priority = 1000,
    init = function()
      vim.g.moonflyVirtualTextColor = true
    end,
  },
  {
    "bjarneo/ash.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      -- Colora leggermente solo le diagnostiche quando è attivo "ash"
      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "ash",
        callback = function()
          local set = vim.api.nvim_set_hl
          set(0, "DiagnosticError",            { fg = "#d16969" })
          set(0, "DiagnosticWarn",             { fg = "#d7ba7d" })
          set(0, "DiagnosticInfo",             { fg = "#7ca5c8" })
          set(0, "DiagnosticHint",             { fg = "#73b59e" })
          set(0, "DiagnosticSignError",        { fg = "#d16969" })
          set(0, "DiagnosticSignWarn",         { fg = "#d7ba7d" })
          set(0, "DiagnosticSignInfo",         { fg = "#7ca5c8" })
          set(0, "DiagnosticSignHint",         { fg = "#73b59e" })
          set(0, "DiagnosticVirtualTextError", { fg = "#d16969", italic = true })
          set(0, "DiagnosticVirtualTextWarn",  { fg = "#d7ba7d", italic = true })
          set(0, "DiagnosticVirtualTextInfo",  { fg = "#7ca5c8", italic = true })
          set(0, "DiagnosticVirtualTextHint",  { fg = "#73b59e", italic = true })
        end,
      })

      pcall(vim.cmd.colorscheme, get_active_scheme())
    end,
  },
}
