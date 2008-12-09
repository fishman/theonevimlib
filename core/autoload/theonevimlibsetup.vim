function! theonevimlibsetup#Setup()
  " give the user the chance to setup this library somewhere else.
  " only do it once
  if config#GetG('tovl#setup', 0) == 1 | return | endif

  " set function which returns list of configuration files to be considered when
  " reading option - only if not yet set
  let F = config#GetG('config#filesFunc', {'default' : library#Function('config#DefaultConfigFiles'), 'set' :1})
  call config#SetG('config#filesFunc', F)
  call config#SetG('config#files', library#Call(F,[]))
  call config#SetG('config#types', library#EvalWhenRequested(library#Function('config#DefaultTypes')))

  call config#GetG('config#tovlPlugin', {'set' : 1, 'default' : tovl#plugin_management#NewPlugin()})

  " add runtime paths of contrib
  for dir in split(glob(expand('<sfile>:h').'/contrib/*'),"\n")
    if isdirectory(dir)
      "set runtimepath+=dir
    endif
  endfor

  " load plugins
  call tovl#plugin_management#UpdatePlugins()

  call config#SetG('tovl#setup', 1)

  command -nargs=* TOVLConfig call config#EditConfig(<f-args>)

  " additional setups see config#TOVLConfigReadCmd()
  augroup TOVL
    au BufReadCmd tovl_config://* call config#TOVLConfigReadCmd()
    au BufWriteCmd tovl_config://* call config#TOVLConfigWriteCmd()
    au BufRead,BufNewFile tovl_config* setlocal ft=tovl_config

    au BufReadCmd tovl_config_default call config#TOVLConfigDefaultReadCmd()
    au BufRead,BufNewFile tovl_config_default setlocal ft=tovl_config
  augroup END

endfunction
