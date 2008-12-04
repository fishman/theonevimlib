function! tofl#plugin_management#PluginDict(p)
   exec "return ".a:p."()"
endfunction


" loads, unloads plugins based on current configuration
function! tofl#plugin_management#UpdatePlugins()
  let loaded = config#GetG('tovl.plugins.loaded',{ 'default' : [], 'set' :1})
  let cfg = config#Get('loadablePlugins', { 'default' : {}})

  " config says they should be active
  let markedActive = tofl#plugin_management#PluginsFromDict([],cfg,"v > 0")

  let toload = tofl#list#Difference(markedActive, loaded)
  let tounload = tofl#list#Difference(loaded, markedActive)

  " try to unload plugins
  for p in tounload
    let d = tofl#plugin_management#PluginDict(p)
    if has_key(d, 'unload')
      try
        exec d['unload']
        call remove(loaded, index(loaded,p))
        echom "unloaded:".p
      catch /.*/
        echom "unloading of plugin ".p." failed due to exception ".v:exception
      endtry
    else
      echom "unloading of plugin ".p." failed, not implemented."
    endif
  endfor

  " try to load plugins and be silent, this will be done on startup as well
  for p in toload
    let d = tofl#plugin_management#PluginDict(p)
    if has_key(d, 'load')
      try
        exec d['load']
        call add(loaded, p)
        echom "loaded: ".p
      catch /.*/
        echom "loading of plugin ".p." failed due to exception ".v:exception
      endtry
    else
      echom "loading of plugin ".p." failed, key 'load' missing."
    endif
  endfor
endfunction

function! tofl#plugin_management#AllPluginFiles()
  let list = []
  for path in split(&runtimepath,",")
    call extend(list, split(glob(path."/autoload/plugins/**.vim"),"\n"))
  endfor
  return list
endfunction

function! tofl#plugin_management#PluginNamesFromFile(file)
  return  map( filter(readfile(a:file),'v:val =~ '.string('^\s*fun[^\S]*\s\+\S\+#Plugin\%(\S*\)'))
        \ , 'matchstr(v:val,'.string('^\s*fun\S*\s\+\zs.*[^(]*\ze(').')')
endfunction

function! tofl#plugin_management#AllPlugins()
  return tofl#list#Concat(
        \ map(tofl#plugin_management#AllPluginFiles(),
              \ 'tofl#plugin_management#PluginNamesFromFile(v:val)'))
endfunction

function! s:PluginsFromDict(path, dict, filter)
  let l = []
  for k in keys(a:dict)
    let v = a:dict[k]
    if type(v) == 4
      " sub dict
      call extend(l, s:PluginsFromDict(a:path + [k], v, a:filter))
    else
      " must be a plugin
      exec "if ".a:filter."| call add(l, a:path+[k]) | endif"
    endif
    unlet v
  endfor
  return l
endfunction

" takes a dictionary as given in the config and returns a list of activated
" 'path#PluginFoo' plugins.
" filter: filter plugins based on exec expressions. "v == 1" will only give
" you valid ones. "v > 0" means activated
function! tofl#plugin_management#PluginsFromDict(path, dict, filter)
  return map(s:PluginsFromDict([],a:dict,"v > 0"), 'join(v:val,"#")')
endfunction

" tidies the dict up.
" if a plugin is marked active but does no longer exist mark it by 2 (instead of 1)
" remove all entries set to 0 which are no longer present
" add new plugins marked 0
function! tofl#plugin_management#TidyUp(dict)
  let all = tofl#plugin_management#AllPlugins()
  let inactive = tofl#plugin_management#PluginsFromDict([], a:dict, "v == 0")
  let markedActive = tofl#plugin_management#PluginsFromDict([], a:dict, "v > 0")

  " mark as 2 when plugin is no longer present
  for p in markedActive
    call config#SetByPath(a:dict, split(p, "#"), index(all, p) >=0 ? 1 : 2)
  endfor

  " remove not activeted plugins which do not exist
  for p in tofl#list#Difference(inactive, all)
    call config#DelByPath(a:dict, split(p, "#"))
  endfor

  " add new plugins marked 0
  for p in all
    if index(markedActive, p) == -1
      call config#SetByPath(a:dict, split(p, "#"), 0)
    endif
  endfor
endfunction
