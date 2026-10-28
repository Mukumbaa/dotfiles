vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking (copying) text",
  callback = function()
    vim.hl.on_yank()
  end,
})
-- ("rounded", "single", "double", "solid", "none")
vim.g.border = "single"

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
  -- ttyfast = true, --faster scrolling
  smoothscroll = true,
  scrolloff = 8,
  sidescrolloff = 8,
  title = true, --automatic window titlebar
  numberwidth = 4,

  autoindent = true,
  smartindent = false,
  cindent = false,

  foldmethod = "expr",
  foldlevel = 99, --disable folding, lower #s enable
  -- foldexpr = "nvim_treesitter#foldexpr()",
  foldexpr = "v:lua.vim.treesitter.foldexpr()",

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
vim.g.netrw_banner = 0
vim.g.netrw_winsize = -30
vim.g.netrw_liststyle = 3
vim.g.netrw_browse_split = 4
vim.opt.whichwrap:append({ ['<'] = true, ['>'] = true, ['h'] = true, ['l'] = true, ['['] = true, [']'] = true })

for k, v in pairs(options) do
  vim.opt[k] = v
end
