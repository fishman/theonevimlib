" userinterface of tovl/ui/multiple_completions.vim
let s:file = expand('<sfile>')
function! plugins#buffer#move_copy#PluginMoveCopyFile()
  let d = {
        \ 'Tags': ['cp','copy','move','mv','rename'],
        \ 'Info': "shortcut for moving or copying a file",
        \ 'cmd' : library#ReadLazy(fnamemodify(s:file,":p:r").'_userinterface.vim',{'join':1}),
        \ }
  return tovl#plugin_management#DefaultPluginDictCmd(d)
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
