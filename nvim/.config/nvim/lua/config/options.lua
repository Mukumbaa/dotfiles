vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking (copying) text",
  callback = function()
    vim.hl.on_yank()
  end,
})


local options = {
  laststatus = 3,
  ruler = false, --disable extra numbering
  showmode = false, --not needed due to lualine
  showcmd = false,
  wrap = true, --toggle bound to leader W
  mouse = "a", --enable mouse
  history = 100, --command line history
  swapfile = false, --swap just gets in the way, usually
  backup = false,
  undofile = true, --undos are saved to file
  cursorline = true, --highlight line
  ttyfast = true, --faster scrolling
  smoothscroll = true,
  scrolloff = 8,
  sidescrolloff = 8,
  title = true, --automatic window titlebar
  numberwidth = 4,

  cindent = true,
  autoindent = false,

  foldmethod = "expr",
  foldlevel = 99, --disable folding, lower #s enable
  foldexpr = "nvim_treesitter#foldexpr()",

  ignorecase = true, --ignore case while searching
  smartcase = true, --but do not ignore if caps are used

  conceallevel = 2, --markdown conceal
  concealcursor = "nc",

  splitkeep = 'screen', --stablizie window open/close

  -- mine
  -- Split Management
  splitright = true,
  splitbelow = true,
  number = true,
  relativenumber = true,
  hlsearch = true,
  incsearch = true,
  smartindent = true,
  smarttab = true, --indentation stuff
  expandtab = true,
  shiftwidth = 2,
  tabstop = 2,
  softtabstop = 2,
  termguicolors = true,
  updatetime = 250,
  signcolumn = "yes",
  clipboard = "unnamedplus",
  -- Completamento automatico nativo
  autocomplete = false,
  -- completeopt = { "menu", "menuone", "noselect" },
  fillchars = { eob = " " },
  background = "dark",
  guifont = "MesloLGS NF:h17",  -- You can adjust the size (h14) as needed

}
vim.opt.undodir = vim.fn.stdpath("data") .. "/undodir"
vim.opt.undofile = true
vim.g.netrw_banner = 0
vim.g.netrw_winsize = -30
vim.g.netrw_liststyle = 3
vim.g.netrw_browse_split = 4

for k, v in pairs(options) do
  vim.opt[k] = v
end

vim.diagnostic.config({
  -- Disattiva i simboli nella barra laterale (mantenendo la tua preferenza attuale)
  signs = false,

  -- Abilita il testo fantasma (Virtual Text)
  virtual_text = {
    spacing = 4,          -- Distanza in spazi tra la fine del codice e il testo fantasma
    source = "if_many",   -- Mostra la sorgente (es. pyright, lua_ls) se ci sono più diagnostiche
    prefix = "■",         -- Simbolo che precede il messaggio d'errore (puoi usare "●", " ", "󰅚 ")
    severity = nil,       -- Mostra tutte le gravità (Error, Warn, Info, Hint)
  },

  -- Mostra le diagnostiche anche mentre stai digitando in Insert Mode (opzionale)
  update_in_insert = false,
})
-- Disattiva la sorgente 'buffer' di cmp SOLO nei file Typst
vim.api.nvim_create_autocmd("FileType", {
  pattern = "typst",
  callback = function()
    local cmp = require("cmp")
    cmp.setup.buffer {
      sources = {
        { name = "nvim_lsp" },
        { name = "luasnip" },
        { name = "path" },
      },
    }
  end,
})
