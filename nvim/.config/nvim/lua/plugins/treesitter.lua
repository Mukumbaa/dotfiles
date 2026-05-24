return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  build = ":TSUpdate",
  lazy = false,
  config = function ()
    local ts = require("nvim-treesitter")

    local parsers = {
      "c", "lua", "vim", "vimdoc", "typescript", "javascript",
      "tsx", "html", "css", "go", "markdown", "cpp", "python", "java", "typst",
      "bash"
    }

    ts.install(parsers)

    vim.api.nvim_create_autocmd("FileType", {
      callback = function(args)
        local max_filesize = 3 * 1024 * 1024 -- 100 KB
        local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(args.buf))

        if ok and stats and stats.size > max_filesize then
          return
        end

        pcall(vim.treesitter.start, args.buf)
      end,
    })
  end
}
