" see also PluginSyntaxChecker
function! plugins#filetype#ruby#PluginRubySupport(p)
  let p = a:p
  let p['Tags'] = ["ruby"]
  let p['Info'] = "small ruby features"
  let p['defaults']['tags'] = ['ruby_support']
  let p['defaults']['tags_buftype'] = {'ruby' : ['ruby_support']}
  let p['defaults']['ruby_executable'] = 'ruby'
  " mappings to evaluate contents of current buffer using ruby-instantiate

  fun! p.RunRubyActionString()
    return 'silent! wa <bar>'
          \ . 'call tovl#runtaskinbackground#Run('.string({'cmd': [self.cfg.ruby_executable, expand('%')],
                                                          \ 'ef' : 'plugins#tovl#errorformats#PluginErrorFormats#ruby', 'onFinishCallbacks' : ['cope']}).')'
  endf
  let p['feat_action'] = {
        \ 'run_ruby' : {
        \   'key': 'run_ruby',
        \   'description': "runs ruby <this file> and loads the result into the quickfix window",
        \   'action' : library#Function('return '. p.s .'.RunRubyActionString()')
        \ }}
  return p
endfunction
