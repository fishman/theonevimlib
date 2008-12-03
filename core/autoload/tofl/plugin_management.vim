
function! tofl#plugin_management#PluginDict(p)
   exec "return plugins#".a:p."#()"
endfunction

" loads, unloads plugins based on current configuration
function! tofl#plugin_management#UpdatePlugins()
  let loaded = config#GetG('tovl.plugins.loaded',{ 'default' : [], 'set' :1})
  let toload = []
  let tounload = []
  let cfg = config#Get('loadablePlugins', { 'default' : {}})

  " difference
  for k in keys(cfg)
    if cfg[k] != (index(loaded, k) >=0)
      if cfg[k] | call add(toload, k) | else | call add(tounload,k)| endif
    endif
  endfor

  " try to unload plugins
  for p in tounload
    let d = tofl#plugin_management#PluginDict(p)
    if has_key(d, 'unload')
      try
        call library#Call(d['unload'])
        call remove(loaded, index(loaded,p))
      catch /.*/
        echo "unloading of plugin ".p." failed due to exception ".v:exception
      endtry
    else
      echo "unloading of plugin ".p." failed, not implemented."
    endif
  endfor

  " try to load plugins and be silent, this will be done on startup as well
  for p in toload
    let d = tofl#plugin_management#PluginDict(p)
    if has_key(d, 'load')
      try
        exec d['load']
        call add(loaded, p)
      catch /.*/
        echo "loading of plugin ".p." failed due to exception ".v:exception
      endtry
    else
      echo "loading of plugin ".p." failed, key 'load' missing."
    endif
  endfor
endfunction

function! tofl#plugin_management#AllPluginFiles()
  let list = []
  for path in split(&runtimepath,",")
    call extend(list, split(glob(path."/autoload/plugins/*.vim"),"\n"))
  endfor
  return list
endfunction

function! tofl#plugin_management#AllPlugins()
  return map(tofl#plugin_management#AllPluginFiles(), "matchstr(v:val,'plugins.\\zs.*\\ze.vim')")
endfunction
