return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  build = ":TSUpdate",
  lazy = false,
  config = function ()
    -- 1. Si chiama il modulo principale, "configs" non esiste più
    local ts = require("nvim-treesitter")

    local parsers = { 
      "c", "lua", "vim", "vimdoc", "typescript", "javascript", 
      "tsx", "html", "css", "go", "markdown", "cpp", "python", "java", "typst"
    }

    -- 2. La nuova API per installare i parser
    ts.install(parsers)

    -- 3. In Neovim 0.12, l'highlighting e l'indentazione si attivano in modo nativo.
    -- Per mantenere la tua logica (disabilitare l'highlight per file più grandi di 100KB),
    -- si usa ora un Autocmd nativo di Neovim:
    vim.api.nvim_create_autocmd("FileType", {
      callback = function(args)
        local max_filesize = 100 * 1024 -- 100 KB
        -- Nota: da Neovim 0.10+, "vim.loop" è stato rinominato in "vim.uv"
        local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(args.buf))
        
        -- Se il file supera la grandezza, usciamo senza attivare treesitter
        if ok and stats and stats.size > max_filesize then
          return
        end
        
        -- Altrimenti, avvia il parser nativo di treesitter per questo buffer
        pcall(vim.treesitter.start, args.buf)
      end,
    })
  end
}
