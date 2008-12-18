" TODO implement loading dependency. Some Plugins should be loaded before
" others
" I'd suggest something like
" 'loadBefdore' : [ 'x', 'y' ] 
" 'loadAfter' : ['z' ] where x, y and z may be plugins or "virtual" targets
" such as "setupmappings"

fun! s:Log(level, msg)
  call tovl#log#Log("tovl#plugin_management",a:level, a:msg)
endf
fun! s:LogExec(level, msg)
  call tovl#log#Log("tovl#plugin_management",a:level, "executing :\n".a:msg)
  exec a:msg
endf

function! tovl#plugin_management#PluginDict(p)
  try
    " try returning loaded plugin first
    return tovl#plugin_management#Plugin(a:p)
  catch /.*/
    let d = deepcopy(config#GetG('config#tovlPlugin'))
    " for convinience at the plugin name
    let d['pluginName'] = a:p
    let d['pluginNameFlat'] = substitute(a:p,'#','_','g')
    let d['s'] = "tovl#plugin_management#Plugin(".string(a:p).")"

    " now load the plugin code
    " return {a:p}(d) makes vim hang when using -V20file or debugging this
    " code.. ! ?
    let r = {a:p}(d)
  endtry
  return r
endfunction

let s:loaded = config#GetG('tovl#plugins#loaded', {'set' : 1, 'default' : {}})

" shared dict -> featureset.vim 
let s:featureTypes = config#GetG('tovl#features#types', {'set' : 1, 'default' : {}})

" return dict of loaded plugin
function! tovl#plugin_management#Plugin(name)
  return s:loaded[a:name]
endfunction

fun! tovl#plugin_management#CompareLoadingOrder(a,b)
  return get(a:a, 'loadingOrder', 100) - get(a:b,'loadingOrder',100)
endf

" loads, unloads plugins based on current configuration
function! tovl#plugin_management#UpdatePlugins()
  let loadedKey = keys(s:loaded)
  let cfg = config#Get('loadablePlugins', { 'default' : {}})

  " config says they should be active
  let markedActive = tovl#plugin_management#PluginsFromDict([],cfg,"v > 0")

  let toload = tovl#list#Difference(markedActive, loadedKey)
  let tounload = tovl#list#Difference(loadedKey, markedActive)

  " try to unload plugins
  for p in tounload
    let d = s:loaded[p]
    if has_key(d, 'Unload')
      try
        call library#Call(d['Unload'],[],d)
        call remove(s:loaded, p)
        call s:Log(1,"unloaded:".p)
      catch /.*/
        call s:Log(0,"exception while unloading of plugin ".p)
      endtry
    else
      call s:Log(0,"exception while unloading plugin ".p)
    endif
  endfor

  let pluginsToLoad = []
  for p in toload
    try
      let d = tovl#plugin_management#PluginDict(p)
      call add(pluginsToLoad, d)
    catch /.*/
      call s:Log(0, "exception while getting plugin dict ".p)
    endtry
  endfor
  call sort(pluginsToLoad, 'tovl#plugin_management#CompareLoadingOrder')
  " try to load plugins and be silent, this will be done on startup as well
  for d in pluginsToLoad
    try
      call library#Call(d['LoadPlugin'],[],d)
      let  s:loaded[d.pluginName] =d
      call s:Log(1, "loaded: ".p)
    catch /.*/
      call s:Log(0, "exception while loading plugin ".d.pluginName)
    endtry
  endfor
endfunction

function! tovl#plugin_management#AllPluginFiles()
  let list = []
  for path in split(&runtimepath,",")
    call extend(list, split(glob(path."/autoload/plugins/**/*.vim"),"\n"))
  endfor
  return list
endfunction

function! tovl#plugin_management#PluginNamesFromFile(file)
  return  map( filter(readfile(a:file),'v:val =~ '.string('^\s*fun[^\S]*\s\+\S\+#Plugin\%(\S*\)'))
        \ , 'matchstr(v:val,'.string('^\s*fun\S*\s\+\zs.*[^(]*\ze(').')')
endfunction

function! tovl#plugin_management#AllPlugins()
  return tovl#list#Concat(
        \ map(tovl#plugin_management#AllPluginFiles(),
              \ 'tovl#plugin_management#PluginNamesFromFile(v:val)'))
endfunction

function! s:PluginsFromDict(path, dict, filter)
  let l = []
  for [k, v] in items(a:dict)
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
function! tovl#plugin_management#PluginsFromDict(path, dict, filter)
  return map(s:PluginsFromDict([],a:dict, a:filter), 'join(v:val,"#")')
endfunction

" tidies the dict up.
" if a plugin is marked active but does no longer exist mark it by 2 (instead of 1)
" remove all entries set to 0 which are no longer present
" add new plugins marked 0
function! tovl#plugin_management#TidyUp(dict)
  let all = tovl#plugin_management#AllPlugins()
  let inactive = tovl#plugin_management#PluginsFromDict([], a:dict, "v == 0")
  let markedActive = tovl#plugin_management#PluginsFromDict([], a:dict, "v > 0")

  " mark as 2 when plugin is no longer present
  for p in markedActive
    call config#SetByPath(a:dict, split(p, "#"), index(all, p) >=0 ? 1 : 2)
  endfor

  " remove not activeted plugins which do not exist
  for p in tovl#list#Difference(inactive, all)
    call config#RemoveByPath(a:dict, split(p, "#"))
  endfor

  " add new plugins marked 0
  for p in all
    if index(markedActive, p) == -1
      call config#SetByPath(a:dict, split(p, "#"), 0)
    endif
  endfor
  return a:dict
endfunction

" this class prototype is written to global option config#tovlPlugin
" this way you can override this in your .vimrc
fun! tovl#plugin_management#NewPlugin()
  let d = tovl#obj#NewObject('tovl plugin')

  " they will be added automatically (see example, Load below)
  let d.autocommands = {}

  " OLD, FIXME! (use new feature stuff)
  let d.mappings = {}
  let d.mappings2 = {}
  let d.commands = {}
  let d.features = {}
  " d.featureExtensions = {}
  let d.removeFeatureTypes = []

  " they have been added and will be removed when unloading a plugin
  let d.mappings_ = []
  let d.aucommands_ = []

  let d.defaults = {'autocommands' :{}, 'commands': {}, 'mappings2' : {}}

  " depreceated: (TODO)
  let d.defaults['mappings'] = {}

  " args: level, msg
  fun! d.Log(...)
    call call('tovl#log#Log', [self.pluginName]+a:000)
  endf

  fun! d.LogExec(level, pre, cmd)
    call self.Log(a:level, a:pre.' '.a:cmd)
    exec a:cmd
  endf

  " registers a new item (mapping, completion func or command)
  " see featureset.vim
  fun! d.RegI(d)
    let d = a:d
    let d['plugin'] = self.pluginName
    " provide default tags
    if !has_key(d, 'tags')
      if !has_key(self.defaults, 'tags')
        throw "request to add feature without 'tags' key. Consider setting  the plugin key defaults.tags = ['your_tag']"
      else
        let d['tags'] = self.defaults.tags
      endif
    endif
    call tovl#featureset#ModifyFeatureItem(d, 'add')
  endf

  " {'events' : events,'pattern' : pattern, 'cmd' : command }
  fun! d.Au(opts)
    if empty(self.aucommands_)
      exec 'augroup '.self.pluginNameFlat.'| augroup end'
    endif
    call add(self.aucommands_, a:opts)
    call self.LogExec(1, 'autocommand: ','au '.self.pluginNameFlat.' '.a:opts['events'].' '.a:opts['pattern'].' '.a:opts['cmd'])
  endf

  fun! d.RegisterFeatureType(ext)
    let ext = a:ext
    let ext['plugin'] = self.pluginName
    if tovl#featureset#RegisterFeatureType(ext)
      call add(self.removeFeatureTypes, ext)
    endif
  endf

  fun! d.Debug(n, f)
    if get(self.cfg, a:n, 0)
      debug return call(a:f,[],self)
    else
      return call(a:f,[],self)
    endif
  endf

  " calls d.Load() if configuration is not empty
  " it is empty after enabling it. If you save the next time defaults will be
  " present
  fun! d.LoadPlugin()
    let self.cfg = config#Get(self.pluginName, {'default' : {}})
    if get(self.cfg,'logAll',0)
      " hacky, but works :-)
      let log = tovl#log#GetLogger()
      let log.whiteList .= '| a:context[:'.(len(self.pluginName)-1).'] == '.string(self.pluginName)
    endif
    if !empty(self.cfg)
      call self.Debug('debugLoad', self.Load)
    endif
  endfun

  fun! d.Load()
    try
      let cfg = self.cfg
      call config#AddToListUniq('config#onChange', library#Function(self['OnConfigChange'],{'self' : self}))

      " add global tags
      let tags = get(self.cfg,'tags',[])
      call tovl#featureset#ModifyTags(0,tags, [])
      " add buffer type tags
      for [k,v] in items(get(self.cfg,'tags_buftype',{}))
        if type(v) != 3
          call self.Log(0, 'tags_buftype key '.k.': The value must be a list of tags, got: '.string(v))
          continue
        endif
        call self.Au({'events' : 'filetype', 'pattern' : k,
          \ 'cmd' : 'call tovl#featureset#ModifyTags(1,'.string(v).', [])' })
        unlet k v
      endfor
      
      " register feature types
      let featT = get(self, 'featureTypes', {})
      for [k, featT] in items(featT)
        let featT['name'] = k
        let f = copy(featT)
        let f['featType'] = k
        call self.RegisterFeatureType(f)
      endfor

      " register feature items
      for [k,dict] in items(s:featureTypes)
        if has_key(cfg, k)
          let featE = cfg[k]
          for [name, v] in items(featE)
            try
              let v['featType'] = k
              if has_key(dict, 'FromConfigApply')
                call library#Call(dict['FromConfigApply'], [v])
              endif
              call self.RegI(v)
            catch /.*/
              e:exception
              call self.Log(0, 'exception while setting feature item '.k.' '.name)
            endtry
            unlet v
          endfor
        endif
      endfor

      for name in keys(self.autocommands)
        try
          let a = copy(self.autocommands[name])
          let a['p'] = cfg.autocommands[name].pattern
          call self.Au(a)
        catch /.*/
          call self.Log(0, 'exception while setting up autocommand '.name.' for '.self.pluginName)
        endtry
      endfor
    catch /.*/ 
      call self.Log(0, 'exception while running d.Load')
    endtry
  endf

  fun! d.Unload()
    " unregister feature extensions
    for e in self.removeFeatureTypes
      call tovl#featureset#UnregisterFeatureType(e['name'])
    endfor

    " unregister notification
    call tovl#list#Remove(config#GetG('config#onChange'),
          \ library#Function(self['OnConfigChange'],{'self' : self}))
    " remove mappings
    call tovl#featureset#DelItemsOfPlugin(self.pluginName)

    " remove mappings and augroup
    if !empty(self.aucommands_)
      exec 'aug! '.self.pluginNameFlat
    endif
    let bm = []
    for m in self.mappings_
      if m['ft'] == ""
        try
          exec m['m'].'unmap '.m['lhs']
        catch /.*/
          call self.Log(0, self.pluginName." error removing mapping ".m['lhs']." ".e:exception)
        endtry
      else
        " Remove mappings from buffers!
        call add(bm, 'bufdo  if maparg('.string(m['lhs']).','.string(m['m']).',"") == '.string(m['rhs'])
                  \ .'|'.m['m'].'unmap <buffer> '.m['rhs']
                  \ .'|endif' )
      endif
    endfor
    try
      if !empty(bm)
          " this might be slow if you have many buffers open ? mapping :e! % could be an alternative
          " bufdo stops at the last buffer processed. There should be no erros. So go on to the buffer we started from
          "exec 'bufdo '.join(bm, "|")
          "bn
      endif
    catch /.*/
      call self.Log(0, 'exception while removing filetype mappings for '.self.pluginName)
    endtry
    let self.mappings_ = []
    let self.aucommands_ = []
  endf

  fun! d.OnConfigChange()
    try
      if self.cfg != config#Get(self.pluginName, {'default': {}})
        call self.Unload()
        call self.LoadPlugin()
      endif
    catch /.*/
      call self.Log(0, "exception while reloading plugin ".self.pluginName)
    endtry
  endfun

  fun! d.DoAddDefaults(dict, p, d)
    for k in keys(a:d)
      let v = a:d[k]
      if type(v) == 4
        " add subkeys
        call self.DoAddDefaults(a:dict, a:p.'#'.k, v)
      else 
        call config#GetByPath(a:dict, a:p.'#'.k, {'default': library#EvalLazy(v), 'set' : 1})
      endif
      unlet v
    endfor
  endfun

  fun! d.AddFeatureDefaultsDefaultFunc(d,i,n,path)
    call config#GetByPath(a:d, a:path.'#'.a:n, {'set' : 1, 'default' : a:i})
  endf

  fun! d.AddDefaultConfigOptions(d)
    for f in keys(s:featureTypes)
      if has_key(self, f)
        if has_key(s:featureTypes[f],'AddDefaults')
          let F = s:featureTypes[f]['AddDefaults']
        else
          let F = self.AddFeatureDefaultsDefaultFunc
        endif
        for k in keys(self[f])
          let feat = copy(self[f][k])
          " remove id and featType before exposing config to user
          if has_key(feat,'id') | call remove(feat, 'id') | endif
          if has_key(feat,'featType') | call remove(feat, 'featType') | endif
          call library#Call(F, [a:d, feat, k, self.pluginName.'#'.f])
        endfor
        unlet F
      endif
    endfor
    for name in keys(self.autocommands)
      let a = self.autocommands[name]
      let x ={'pattern' : a['pattern']}
      let self.defaults.autocommands[name] = x
    endfor
    call self.DoAddDefaults(a:d, self.pluginName, self.defaults)
  endf
  return d
endfun
