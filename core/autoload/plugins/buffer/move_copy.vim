" userinterface of tovl/ui/multiple_completions.vim
function! plugins#buffer#move_copy#PluginMoveCopyFile(p)
  let p = a:p
  let p['Tags'] = ['cp','copy','move','mv','rename']
  let p['Info'] = "shortcut for moving or copying a file"
  let p['defaults']['tags'] = ['file_handling']

  " FIXME: those mappings require the commands!
  let p['feat_mappings'] = {
    \ 'copy' : {
      \ 'lhs' : '<leader>cp',
      \ 'rhs' : ':ContinueWorkOnCopy<space>'
            \ . '<c-r>=expand("%")<cr>'
            \ . '<c-r>=substitute(setcmdpos(getcmdpos()-strlen(expand("%:t"))),".","","g")<cr>' 
     \ },
    \ 'move' : {
      \ 'lhs' : '<leader>mv',
      \ 'rhs' : ':RenameFile<space>'
            \ . '<c-r>=expand("%")<cr>'
            \ . '<c-r>=substitute(setcmdpos(getcmdpos()-strlen(expand("%:t"))),".","","g")<cr>'
      \ }
    \ }

  let p['feat_command'] = {
      \ 'continue_work_on_copy' : {
        \ 'name' : 'ContinueWorkOnCopy',
        \ 'attrs' : '-nargs=1 -complete=file',
        \ 'cmd' : ':call plugins#buffer#move_copy#ContinueWorkOnCopy(<f-args>)<<cr>'
      \ },
      \ 'rename_file' : {
        \ 'name' : 'ContinueWorkOnCopy',
        \ 'attrs' : '-nargs=1 -complete=file',
        \ 'cmd' : ':call plugins#buffer#move_copy#RenameFile(<f-args>)<<cr>'
      \ }
    \ }
  return p
endfunction

fun! plugins#buffer#move_copy#RenameFile(newname)
  let file = expand('%')
  exec 'saveas '.a:newname
  if delete(file) !=0
    echoe "could'n delete file ". file
  endif
endfun

fun! plugins#buffer#move_copy#ContinueWorkOnCopy(newname)
  let file = expand('%')
  exec 'saveas '.a:newname
endfun
