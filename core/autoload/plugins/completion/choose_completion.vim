function! plugins#completion#choose_completion#PluginChooseCompletionFunc(p)
  let p = a:p
  let p['Tags'] = ['completion']
  let p['Info'] = "interface for tovl/ui/multiple_completions.vim"
  let p['defaults']['tags'] = ['multiple_completion_funcs']

  " run this to fix prefixes of autoload functions (remember that you can use undo.. :-)
  let p['mappings'] = {
    \ 'fix_funtion_prefixes' : {
      \ 'lhs' : '',
      \ 'rhs' : ':call tovl#ui#multiple_completions#ChooseCompletionFunc()<cr>' } }
  let p['mappings'] = {
    \ 'fix_funtion_prefixes' : {
      \ 'name' : 'ChooseCompletionFunc',
      \ 'cmd' : 'call tovl#ui#multiple_completions#ChooseCompletionFunc()' } }
  return p
endfunction
