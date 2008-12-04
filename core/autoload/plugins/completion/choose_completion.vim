" userinterface of tovl/ui/multiple_completions.vim
function! plugins#completion#choose_completion#PluginChooseCompletionFunc()
  let d = {
        \ 'Tags': ['completion'],
        \ 'Info': "interface for tovl/ui/multiple_completions.vim",
        \ 'cmd' : "command! ChooseCompletionFunc call tovl#ui#multiple_completions#ChooseCompletionFunc()"
        \ }
  return tovl#plugin_management#DefaultPluginDictCmd(d)
endfunction
