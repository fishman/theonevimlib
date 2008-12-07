" userinterface of tovl/ui/multiple_completions.vim
function! plugins#buffer#move_copy#PluginMoveCopyFile(p)
  let p = a:p
  let p['Tags'] = ['cp','copy','move','mv','rename']
  let p['Info'] = "shortcut for moving or copying a file"
  let p['mappings']['copy'] = {
    \ 'ft' : '', 'm':'n', 'lhs' : '<leader>cp',
    \ 'rhs' : ':ContinueWorkOnCopy<space>'
          \ . '<c-r>=expand("%")<cr>'
          \ . '<c-r>=substitute(setcmdpos(getcmdpos()-strlen(expand("%:t"))),".","","g")<cr>' }
  let p['mappings']['move'] = {
    \ 'ft' : '', 'm':'n', 'lhs' : '<leader>mv',
    \ 'rhs' : ':RenameFile<space>'
          \ . '<c-r>=expand("%")<cr>'
          \ . '<c-r>=substitute(setcmdpos(getcmdpos()-strlen(expand("%:t"))),".","","g")<cr>' }
  let child = {}
  fun! child.Load()
    " I don't have functions for commands yet :-( (TODO)
    command! -nargs=1 -complete=file RenameFile :call plugins#buffer#move_copy#RenameFile(<f-args>)<<cr>
    command! -nargs=1 -complete=file ContinueWorkOnCopy :call plugins#buffer#move_copy#ContinueWorkOnCopy(<f-args>)<<cr>
    call self.Parent_Load()
  endf
  fun! child.Unload()
    delc RenameFile
    delc ContinueWorkOnCopy
    call self.Parent_Unload()
  endf
  return p.createChildClass(p.pluginName, child)
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
