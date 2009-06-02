" mind the comment below
" this is very simple yet useful

function! plugins#plone#PluginPlone(p)
  let p = a:p
  let p['Tags'] = ['plone']
  let p['Info'] = "Rerun buildout automatically"
  let p['defaults']['configDummy'] = "make this plugin load cause it hasn't any options"

  fun! p.buildOut(buildoutfile)
    " this input message isn't shown, why?
    if input('restart plone? [y]') == "y"
      let zinstance = fnamemodify(a:buildoutfile,':h')
      let plonectl = zinstance.'/bin/plonectl'
      let commands = [
        \   tovl#runtaskinbackground#EscapeShArg(plonectl).' stop'
        \ , zinstance.'/bin/buildout'
        \ , tovl#runtaskinbackground#EscapeShArg(plonectl).' start'
        \ ]
      call tovl#runtaskinbackground#Run({'cmd' :['sh','-c', join(commands,';')]
            \ ,'ef' : 'plugins#tovl#errorformats#PluginErrorFormats#python' })
    endif
  endf

  let child = {}
  fun! child.Load()
        call self.Au({'events': 'bufwritepost', 'pattern': 'buildout.cfg',
              \ 'cmd': "silent! call ". self.s .".buildOut(expand('%:p'))" })
    call self.Parent_Load()
  endf
  return p.createChildClass(child)
endfunction
