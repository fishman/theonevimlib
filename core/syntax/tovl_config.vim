syn match  Identifier "^\s*[^ \t=]\+:"
runtime! syntax/vim.vim
setlocal autoindent
setlocal fdm=expr
setlocal foldexpr=config#Fold(v:lnum)

for i in ['string','number','faked_function_reference','list','dictionary']
  exec 'syn match Type '.string(i.'=')
endfor
