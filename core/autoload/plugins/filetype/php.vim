" see also PluginSyntaxChecker
function! plugins#filetype#php#PluginPHPSupport(p)
  let p = a:p
  let p['Tags'] = ["php"]
  let p['Info'] = "small php features"
  let p['defaults']['tags'] = ['php_support']
  let p['defaults']['tags_buftype'] = {'php' : ['php_support']}
  let p['defaults']['php_executable'] = 'php'
  " mappings to evaluate contents of current buffer using php-instantiate

  fun! p.RunPHPActionString()
    return 'wa <bar>'
          \ . 'call tovl#runtaskinbackground#Run('.string({'cmd': [self.cfg.php_executable, expand('%')],
                                                          \ 'ef' : 'plugins#tovl#errorformats#PluginErrorFormats#php', 'onFinishCallbacks' : ['cope']}).')'
  endf
  let p['feat_action'] = {
        \ 'run_php' : {
        \   'key': 'run_php',
        \   'description': "runs php <this file> and loads the result into the quickfix window",
        \   'action' : library#Function('return '. p.s .'.RunPHPActionString()')
        \ }}
  return p
endfunction
