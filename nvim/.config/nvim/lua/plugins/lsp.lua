return {
  'neovim/nvim-lspconfig',
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
  },
  config = function()
    vim.lsp.log.set_level("error")

    -- Configurazione hover border (modo moderno)
    -- vim.lsp.handlers["textDocument/hover"] = function(err, result, context, config)
      --     vim.lsp.handlers.hover(err, result, context, { border = "single" })
      -- end

      local capabilities = require('cmp_nvim_lsp').default_capabilities()
      local lsp_keymaps = function(_, bufnr)
        local opts = { buffer = bufnr }
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
        vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
        vim.keymap.set("n", "gt", vim.lsp.buf.type_definition, opts)
        vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
        -- vim.keymap.set("n", "<leader>df", vim.diagnostic.goto_next, opts)
        vim.keymap.set("n", "<leader>j", function()
          vim.diagnostic.jump({ count = 1 })
        end, opts)

        -- vim.keymap.set("n", "<leader>dp", vim.diagnostic.goto_prev, opts)
        vim.keymap.set("n", "<leader>k", function()
          vim.diagnostic.jump({ count = -1 })
        end, opts)

        vim.keymap.set("n", "<leader>R", vim.lsp.buf.rename, opts)
        vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
        -- vim.keymap.set("n", "<leader>Fr", require("telescope.builtin").lsp_references, opts)
        -- vim.keymap.set("n", "<leader>e", function()
          --   vim.diagnostic.open_float(nil, {focusable = false, scope = "line", max_width = 80, border = "single"})
          -- end, opts)
        end

        vim.lsp.config("clangd", {
          capabilities = capabilities,
          on_attach = lsp_keymaps,
          cmd = { "clangd", "--compile-commands-dir=build" },
          -- root_dir = require("lspconfig.util").root_pattern("compile_commands.json", ".git"),
        })

        vim.lsp.config("gopls", {
          capabilities = capabilities,
          on_attach = lsp_keymaps,
        })

        vim.lsp.config("qmlls", {
          capabilities = capabilities,
          on_attach = lsp_keymaps,
        })

        vim.lsp.config("zls", {
          capabilities = capabilities,
          on_attach = lsp_keymaps,
          cmd = { "zls" },
          filetypes = { "zig" },

        })

        -- vim.lsp.config("pyright", {
          --     capabilities = capabilities,
          --     on_attach = lsp_keymaps,
          -- })

          vim.lsp.config("lua_ls", {
            capabilities = capabilities,
            on_attach = lsp_keymaps,
            cmd = { "lua-language-server" },

          })
vim.lsp.config("tinymist", {
  capabilities = capabilities,
  on_attach = function(client, bufnr)
    lsp_keymaps(client, bufnr)

    vim.keymap.set("n", "<leader>tp", function()
      local current_buf = vim.api.nvim_get_current_buf()
      local current_file = vim.api.nvim_buf_get_name(current_buf)
      client:request("workspace/executeCommand", {
        command = "tinymist.startDefaultPreview",
        arguments = { current_file },
      }, function(err)
        if err then
          vim.notify("Errore anteprima Tinymist: " .. err.message, vim.log.levels.ERROR)
        else
          vim.notify("Preview avviata per " .. vim.fn.fnamemodify(current_file, ":t"), vim.log.levels.INFO)
        end
      end, current_buf)
    end, { buffer = bufnr })
  end,

  cmd = { "tinymist" },

  settings = {
    preview = {
      browsing = {
        args = {
          "--data-plane-host=127.0.0.1:0",
          "--invert-colors=never",
          "--open",
        },
      },
    },

    tinymist = {
      preview = {
        invertColors = "never",
      },
    },
  },
})
          vim.lsp.enable({
            "lua_ls",
            "clangd",
            "gopls",
            "pyright",
            "tinymist",
            "zls",
            "qmlls"
          })

        end,
      }
