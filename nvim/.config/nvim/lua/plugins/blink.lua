-- return {
  --   "saghen/blink.cmp",
  --   -- Usa una release precompilata (scarica automaticamente i binari Rust)
  --   version = "*",
  --   event = "InsertEnter",
  return {
    "saghen/blink.cmp",
    -- Scarica i binari precompilati per la tua piattaforma
    version = "*",
    lazy = false, -- Carica all'avvio per fornire subito le capabilities all'LSP
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      -- Keymap ispirate alla tua configurazione precedente (Tab / S-Tab per scorrere, Invio per confermare)
      keymap = {
        preset = "none",
        ["<Tab>"] = { "select_next", "fallback" },
        ["<S-Tab>"] = { "select_prev", "fallback" },
        ["<CR>"] = { "accept", "fallback" },
        ["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
        ["<C-e>"] = { "hide", "fallback" },
        ["<C-b>"] = { "scroll_documentation_up", "fallback" },
        ["<C-f>"] = { "scroll_documentation_down", "fallback" },
      },

      completion = {
        -- Mostra la documentazione in un riquadro a comparsa automatico
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
          window = { border = vim.g.border },
        },
        menu = {
          border = vim.g.border,
          max_height = 10,
          draw = {
            columns = { { "label", "label_description", gap = 1 }, { "kind_icon", "kind" } },
          },
        },
        -- Non seleziona automaticamente il primo elemento finché non premi Tab
        list = {
          selection = {
            preselect = false,
            auto_insert = false,
          },
        },
      },

      sources = {
        -- Configurazione globale predefinita
        default = { "lsp", "path", "snippets", "buffer" },

        -- Disattiva la sorgente 'buffer' specificamente per i file Typst
        -- (la stessa regola che avevi nell'autocomando di options.lua)
        per_filetype = {
          typst = { "lsp", "path", "snippets" },
        },

        min_keyword_length = function(ctx)
          -- Come avevi prima: i suggerimenti dal buffer appaiono solo dopo 3 caratteri
          if ctx.source_name == "buffer" then return 3 end
          return 0
        end,
      },

      -- Completamento per la command line (: e /)
      -- Completamento per la command line (: e /)
      cmdline = {
        enabled = true,
        keymap = {
          preset = "cmdline",
        },
        completion = {
          menu = {
            auto_show = true, -- Mostra subito il menu
          },
          list = {
            selection = {
              preselect = false, -- Non preseleziona nulla automaticamente
              auto_insert = true, -- APPENA premi Tab, inserisce subito la parola nella barra!
            },
          },
        },
      },
    },
  }
