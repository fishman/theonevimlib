syn match  Identifier "^\s*\S\+:"
runtime! syntax/vim.vim
setlocal autoindent
setlocal fdm=expr
setlocal foldexpr=config#Fold(v:lnum)
