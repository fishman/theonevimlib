" userinterface of tovl/ui/multiple_completions.vim
let s:file = expand('<sfile>')
function! plugins#filetype#vim#vl_repo#PluginVL_RepoStuff()
  let d = {
        \ 'Tags': ['buffer','demo'],
        \ 'Info': "most useful parts of my older vim completion and scripting stuff",
        \ 'cmd' : library#ReadLazy(fnamemodify(s:file,":p:r").'_userinterface.vim',{'join':1}),
        \ 'filetype' : 'vim'
        \ }
  return tovl#plugin_management#DefaultPluginDictCmd(d)
endfunction
