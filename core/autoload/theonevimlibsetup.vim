function! theonevimlibsetup#Setup()
  " set function which returns list of configuration files to be considered when
  " readin option - only if not yet set
  let F = config#GetG('configFilesFunc', library#Function('config#DefaultConfigFiles'))
  call config#SetG('configFilesFunc', F)
  call config#SetG('configFiles', library#Call(F,[]))
  call config#SetG('config.types', library#EvalWhenRequested(library#Function('config#DefaultTypes')))

  " add runtime paths of contrib
  for dir in split(glob(expand('<sfile>:h').'/contrib/*'),"\n")
    if isdirectory(dir)
      set runtimepath+=dir
    endif
  endfor
  " load activated plugins
  for plugin in config#Get('plugins', [])
    " Maybe there is a better name than just Info ?
    try
      exec 'let dict = plugins#'.plugin.'#s:Info()'
      " load the plugin
      exec dict['load']
    catch  /.*/
      echoe "failed getting info dictionary of plugin :".plugin
    endtry
  endfor
endfunction
