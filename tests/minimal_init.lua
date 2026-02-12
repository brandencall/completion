vim.opt.runtimepath:append(".")
vim.opt.runtimepath:append("./plenary.nvim")

vim.cmd("runtime plugin/plenary.vim")
vim.opt.swapfile = false
vim.opt.writebackup = false
vim.opt.backup = false
vim.opt.undofile = false

vim.env.LAZY_STDPATH = vim.fn.stdpath("data")

