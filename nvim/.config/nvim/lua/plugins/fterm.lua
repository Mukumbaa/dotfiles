return {
    {
        'numToStr/FTerm.nvim',
        config = function()
            require('FTerm').setup({
                border = vim.g.border, -- <-- Stesso bordo per il terminale
            })
            vim.keymap.set('n', '<leader>z', ":lua require('FTerm').open()<CR>")
            vim.keymap.set('t', '<Esc>', '<C-\\><C-n><CMD>lua require("FTerm").close()<CR>')
        end,
    }
}
