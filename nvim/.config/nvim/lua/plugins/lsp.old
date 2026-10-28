return {
  'neovim/nvim-lspconfig',
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
  },
  config = function()
    vim.lsp.log.set_level("error")

    vim.diagnostic.config({
      float = { border = "rounded" },
    })

    local capabilities = require('cmp_nvim_lsp').default_capabilities()
    vim.lsp.config('*', {
      capabilities = capabilities,
    })

    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
      callback = function(event)
        local opts = { buffer = event.buf }

        vim.keymap.set("n", "K", function()
          vim.lsp.buf.hover({ border = "rounded" })
        end, opts)
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
        vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
        vim.keymap.set("n", "gy", vim.lsp.buf.type_definition, opts)
        vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
        vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)

        vim.keymap.set("n", "<leader>j", function() vim.diagnostic.jump({ count = 1 }) end, opts)
        vim.keymap.set("n", "<leader>k", function() vim.diagnostic.jump({ count = -1 }) end, opts)

        vim.keymap.set("n", "<leader>R", vim.lsp.buf.rename, opts)
        vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
      end,
    })

    vim.lsp.config("clangd", {
      cmd = {
        "clangd",
        "--background-index",
        "--clang-tidy",
        "--completion-style=detailed",
        "--header-insertion=never",
        "--query-driver=/usr/bin/gcc",
      },
      init_options = {
        fallbackFlags = { "-fblocks", "-Wall" },
      },
    })

    vim.lsp.config("basedpyright", {
      cmd = { "basedpyright-langserver", "--stdio" },
      root_markers = {
        "pyproject.toml",
        "setup.py",
        "setup.cfg",
        "requirements.txt",
        "Pipfile",
        "pyrightconfig.json",
        ".git",
        "venv",
        ".venv",
      },
    })

    vim.lsp.config("lua_ls", {
      settings = {
        Lua = {
          diagnostics = { globals = { "vim" } },
          workspace = { checkThirdParty = false },
        },
      },
    })

    vim.lsp.config("tinymist", {
      on_attach = function(client, bufnr)
        vim.keymap.set("n", "<leader>tp", function()
          local current_buf = vim.api.nvim_get_current_buf()
          local current_file = vim.api.nvim_buf_get_name(current_buf)

          client:request("workspace/executeCommand", {
            command = "tinymist.startDefaultPreview",
            arguments = { current_file, "--invert-colors=never" },
          }, function(err)
            if err then
              vim.notify("Errore anteprima Tinymist: " .. err.message, vim.log.levels.ERROR)
            else
              vim.notify("Preview avviata per " .. vim.fn.fnamemodify(current_file, ":t"), vim.log.levels.INFO)
            end
          end, current_buf)
        end, { buffer = bufnr })
      end,
      settings = {
        preview = {
          invertColors = "never",
          browsing = {
            args = {
              "--data-plane-host=127.0.0.1:0",
              "--invert-colors=never",
              "--open",
            },
          },
          background = {
            args = {
              "--data-plane-host=127.0.0.1:23635",
              "--invert-colors=never",
            },
          },
        },
      },
    })

    vim.lsp.enable({
      "clangd",
      "gopls",
      "qmlls",
      "zls",
      "basedpyright",
      "lua_ls",
      "tinymist",
    })
  end,
}
