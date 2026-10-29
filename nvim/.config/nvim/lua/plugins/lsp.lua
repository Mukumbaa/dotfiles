return {
  "neovim/nvim-lspconfig",
  dependencies = {
    "saghen/blink.cmp",
  },
  config = function()
    vim.lsp.log.set_level("error")

    vim.diagnostic.config({
      signs = false,
      update_in_insert = false,
      float = {
        border = vim.g.border,
        source = "if_many",
      },
      virtual_text = {
        spacing = 4,
        source = "if_many",
        prefix = "■",
        severity = nil,
      },
    })

    local capabilities = require("blink.cmp").get_lsp_capabilities()
    vim.lsp.config("*", {
      capabilities = capabilities,
    })

    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
      callback = function(event)
        local map = function(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = event.buf, desc = desc })
        end

        map("n", "K", function()
          vim.lsp.buf.hover({ border = vim.g.border })
        end, "Hover documentation")
        map("n", "gd", vim.lsp.buf.definition, "Goto definition")
        map("n", "gD", vim.lsp.buf.declaration, "Goto declaration")
        map("n", "gy", vim.lsp.buf.type_definition, "Goto type definition")
        map("n", "gi", vim.lsp.buf.implementation, "Goto implementation")
        map("n", "gr", vim.lsp.buf.references, "Goto references")

        map("n", "<leader>j", function() vim.diagnostic.jump({ count = 1 }) end, "Next diagnostic")
        map("n", "<leader>k", function() vim.diagnostic.jump({ count = -1 }) end, "Previous diagnostic")

        map("n", "<leader>R", vim.lsp.buf.rename, "Rename symbol")
        map("n", "<leader>ca", vim.lsp.buf.code_action, "Code action")

        map("n", "<leader>cd", function()
          vim.diagnostic.open_float({ border = vim.g.border, focusable = true })
        end, "Show line diagnostics")

        map("n", "<leader>cy", function()
          local line = vim.fn.line(".") - 1
          local col = vim.fn.col(".") - 1
          local diags = vim.diagnostic.get(0, { lnum = line })
          if #diags == 0 then
            return vim.notify("No diagnostic on this line", vim.log.levels.WARN)
          end

          local target = diags[1].message
          for _, d in ipairs(diags) do
            if col >= d.col and col <= (d.end_col or d.col) then
              target = d.message
              break
            end
          end

          vim.fn.setreg("+", target)
          vim.notify("Diagnostic copied to clipboard", vim.log.levels.INFO)
        end, "Copy line diagnostic")

        map("n", "<leader>cg", function()
          local line = vim.fn.line(".") - 1
          local diags = vim.diagnostic.get(0, { lnum = line })
          if #diags == 0 then
            return vim.notify("No diagnostic on this line", vim.log.levels.WARN)
          end

          local msg = diags[1].message:gsub("\n", " "):gsub("%s+", " ")
          local query = (vim.bo.filetype or "") .. " " .. msg
          local encoded = query:gsub("[^%w _~%.%-]", function(c)
            return string.format("%%%02X", string.byte(c))
          end):gsub(" ", "+")

          vim.ui.open("https://www.google.com/search?q=" .. encoded)
        end, "Search diagnostic on Google")
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
              vim.notify("Tinymist preview error: " .. err.message, vim.log.levels.ERROR)
            else
              vim.notify("Preview started for " .. vim.fn.fnamemodify(current_file, ":t"), vim.log.levels.INFO)
            end
          end, current_buf)
        end, { buffer = bufnr, desc = "Start Typst preview" })
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
