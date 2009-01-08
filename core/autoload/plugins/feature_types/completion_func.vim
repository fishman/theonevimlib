function! plugins#feature_types#completion_func#PluginCompletion(p)
  let p = a:p
  let p['Tags'] = []
  let p['Info'] = "let's your provide completion fucntions from which the user can choose"
  let p['defaults']['tags'] = ['completion_func']

  let p['loadingOrder'] = 50
  let p['feat_mapping'] = {
      \ 'goto_to_thing_at_cursor' : {
        \ 'lhs' : 'gf',
        \ 'rhs' : ':call tovl#ui#goto_thing_at_cursor#HandleOnThing()<cr>' 
      \ }
    \ }
  let p['featureTypes'] = {
      \ 'feat_completion_func' : {
        \ 'AddItem' : library#Function('tovl#ui#multiple_completions#RegisterBufferCompletionFunc'),
        \ 'DelItem' : library#Function('tovl#ui#multiple_completions#UnregisterBufferCompletionFunc'),
        \ 'FromConfigApply' : library#Function('let ARGS[0]["buffer"] = 1')
      \ }}

  let p['feat_mapping'] = {
    \ 'fix_funtion_prefixes' : {
      \ 'lhs' : '',
      \ 'rhs' : ':call tovl#ui#multiple_completions#ChooseCompletionFunc()<cr>' } }
  let p['feat_command'] = {
    \ 'fix_funtion_prefixes' : {
      \ 'name' : 'ChooseCompletionFunc',
      \ 'cmd' : 'call tovl#ui#multiple_completions#ChooseCompletionFunc()' } }
  return p
endfunction
