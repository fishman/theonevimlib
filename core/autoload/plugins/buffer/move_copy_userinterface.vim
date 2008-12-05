map <leader>cp :ContinueWorkOnCopy<space>
  \<c-r>=expand('%')<cr>
  \<c-r>=substitute(setcmdpos(getcmdpos()-strlen(expand('%:t'))),'.','','g')<cr>
map <leader>mv :RenameFile<space>
  \<c-r>=expand('%')<cr>
  \<c-r>=substitute(setcmdpos(getcmdpos()-strlen(expand('%:t'))),'.','','g')<cr>
map <leader>rm :!rm %<cr>

command! -nargs=1 -complete=file RenameFile :call plugins#buffer#move_copy#RenameFile(<f-args>)<<cr>
command! -nargs=1 -complete=file ContinueWorkOnCopy :call plugins#buffer#move_copy#ContinueWorkOnCopy(<f-args>)<<cr>
