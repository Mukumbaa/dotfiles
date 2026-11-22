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
        config = function()
            pcall(vim.cmd.colorscheme, get_active_scheme())
        end,
    },
}
