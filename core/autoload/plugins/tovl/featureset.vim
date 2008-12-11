" interface for core/autoload/tovl/featureset.vim
function! plugins#tovl#featureset#PluginFeatureSet(p)
  let p = a:p
  let p['Tags'] = ['featureset', 'filetype']
  let p['Info'] = "Manage feature sets."

  " if there is a .cabal file setup compilation mappings etc automatically
  let p['defaults']['tags'] = ['featureset']

  let p['commands']['modify_buffer_feature_tags'] = {
    \ 'name' : 'BufferFeatureTags',
    \ 'attrs' : '-nargs=* -complete=customlist,tovl#featureset#CommandCompletionBuffer',
    \ 'cmd' : 'call tovl#featureset#CommandAction(1, <f-args>)',
    \ 'tags' : ['featureset']
    \ }
  let p['commands']['modify_global_feature_tags'] = {
    \ 'name' : 'GlobalFeatureTags',
    \ 'attrs' : '-nargs=* -complete=customlist,tovl#featureset#CommandCompletionGlobal',
    \ 'cmd' : 'call tovl#featureset#CommandAction(0,<f-args>)',
    \ 'tags' : ['featureset']
    \ }
  return p
endfunction
