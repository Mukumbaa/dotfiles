return {
  "goolord/alpha-nvim",
  event = "VimEnter",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    local dashboard = require("alpha.themes.dashboard")

    dashboard.section.header.val = {
      [[]],
      [[]],
      [[]],
      [[]],
      [[]],
      [[]],
      [[]],
      [[]],
      [[███    ██ ███████  ██████  ██    ██ ██ ███    ███]],
      [[████   ██ ██      ██    ██ ██    ██ ██ ████  ████]],
      [[██ ██  ██ █████   ██    ██ ██    ██ ██ ██ ████ ██]],
      [[██  ██ ██ ██      ██    ██  ██  ██  ██ ██  ██  ██]],
      [[██   ████ ███████  ██████    ████   ██ ██      ██]]
    }

    dashboard.section.buttons.val = {
      dashboard.button("f", "󰍉  Find file", ":lua require('fzf-lua').files() <CR>"),
      dashboard.button("o", "󰍉  Find old file", ":lua require('fzf-lua').oldfiles() <CR>"),
      dashboard.button("t", "  Browse cwd", ":NvimTreeOpen<CR>"),
      dashboard.button("c", "  Config", ":NvimTreeOpen ~/.config/nvim/<CR>"),
      dashboard.button("m", "  Mappings", ":e ~/.config/nvim/lua/config/keymaps.lua<CR>"),
      dashboard.button("q", "󰅙  Quit", ":q!<CR>"),
    }

    dashboard.section.footer.val = function()
      local stats = require("lazy").stats()
      local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
      return "󱐌 Neovim caricato in " .. ms .. "ms"
    end

    dashboard.section.header.opts.hl = "AlphaHeader"
    dashboard.section.buttons.opts.hl = "Keyword"
    dashboard.opts.opts.noautocmd = true

    require("alpha").setup(dashboard.opts)
  end,
}
