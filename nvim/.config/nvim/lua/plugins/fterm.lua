return {
    {
        'numToStr/FTerm.nvim',
        config = function()
            vim.keymap.set('n', '<leader>z', ":lua require('FTerm').open()<CR>")             --open term
            vim.keymap.set('t', '<Esc>', '<C-\\><C-n><CMD>lua require("FTerm").close()<CR>') --preserves session
        end,
    }
}
