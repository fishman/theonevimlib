syn match  Identifier "^\s*\S\+:"
runtime! syntax/vim.vim
setlocal autoindent
set fdm=expr
set foldexpr=config#Fold(v:lnum)
