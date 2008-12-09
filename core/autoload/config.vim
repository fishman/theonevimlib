" a union way to configure theonelib and  plugins:
"
" SetByPath, GetByPath define functions to set values within hirarchical dicts
" SetG GetG use those to get global settings (you know about (deep)copy() ?)
" config#files is the list which will be checked for configuration settings.
" The head of the list (index 0) is the main global user config.
" config#filesFunc is the function reference beeing executed once on startup
" returning this list. You can override it in your .vimrc.
" All plugins are encouraged to automatically create their settings in the 
" main config. The its up to you to edit them.
"
" if multiple configuration files contains the same value a plugin can specify
" a merge function
" eg call SetG('config#configpath#merge', function(my#MergeLists))
" If you would try to get the option config#configpath#foo#bar#merge
" ['foo','bar'] would be fed into my#MergeLists which should return a merge
" function itself

" To read or write configuration options use
" config#Get(path, default) 
" config#Set(path, value) # default config
" config#Set(path, value, file) # write to this config
"   This increases performance if you want to set many settings at once
"   After having changed the configs use config#WriteConfigs() to flush contents

" You can register an callback function which will be triggered when
" configuration changes this way:
" call config#AddToList('config#onChange', library#Function('myFun'))
" the event will only be triggered when flushing hasn't been delayed or on
" flush
"
" Note: using # as separator to allow keys such as www.company.foo which
" could be a plugin directory.


" which is your .vim directory where you keep your custom stuff?
" Eg this is used to define some mappings opening ftplugin files
fun! config#DotVim()
  return config#GetG('config#.vim', split(&runtimepath,',')[0])
endf

function! config#AddToListUniq(path, v)
  call tovl#list#AddUnique(config#GetG(a:path, {'set' : 1, 'default' : []}),a:v)
endfunction

function! config#FireEvent(path, ...)
  for F in config#GetG(a:path, [])
    call call(function("library#Call"), [F] + [a:000])
  endfor
endfunction

function! config#Path(path)
  if type(a:path) == 1
    return split(a:path,'#')
  else 
    return a:path
  endif
endfunction

" SetByPath(dict, "a#b", 3) is equal to
" SetByPath(dict, ["a","b"], 3) is equal to
function! config#SetByPath(dict, path, value)
  let path = config#Path(a:path)
  let d = a:dict
  for p in path[:-2]
    if !has_key(d, p)
      let d[p] = {}
    endif
    let d = d[p]
  endfor
  let d[path[-1]] = a:value
  return a:value
endfunction

function! config#RemoveByPath(dict, path, ...)
  let removeEmptyDicts =  a:0 > 0 ? a:1 : 1
  let path = config#Path(a:path)
  let idx = 0
  let head = path[0]
  if has_key(a:dict, head)
    if len(path) == 1
      call remove(a:dict, head)
    else
      let v = a:dict[head]
      call config#RemoveByPath(v, path[1:], removeEmptyDicts)
      if removeEmptyDicts && empty(v)
        call remove(a:dict, head)
      endif 
    endif
  endif
endfunction

function! config#DefaultConfigFiles()
  " adding per directory project configuration files would be cool.
  " But maybe this is bad for security? Ask the user once and store md5sum?
  return [expand('$HOME').'/.theonevimlib_config']
endfunction

" if foo#bar is set to a function ref that will be passed the remaining path
" and its result is returned
" usage example: GetByPath('foo#bar', {'set' : 1, 'default' : {}})
" GetByPath('foo', 2) shortcut for GetByPath('foo',{'default' : 2})
" will return setting foo#bar and set it to the default value {} if it hasn't been set yet
function! config#GetByPath(dict, path, ...)
  if a:0 > 0
    let opts = a:1
    if type(opts) != 4
      " shortcut, if arg is not a dict its the default value
      let o = opts | unlet opts
      let opts = {'default' : o}
      unlet o
    endif
  else
    let opts = {}
  endif
  if has_key(opts, 'default')
    let default = 'return library#EvalLazy(opts["default"])'
    if get(opts, 'set', 0)
      let default = 'call config#SetByPath(a:dict, a:path, opts["default"])|'.default
    endif 
  else
    let default = 'throw '.string("no default value given, GetByPath path: ".string(a:path))
  endif
  let path = config#Path(a:path)
  if len(path) ==0
    return a:dict
  endif
  let d = a:dict
  let idx = 0
  while idx < len(path)-1
    let p = path[idx]
    if !has_key(d, p)
      exec default
    endif
    " handle function
    let PF = d[p]
    if type(PF) == 2
      return library#EvalLazy(PF(path[idx+1:]))
    else
      let d = PF
    endif
    unlet PF
    let idx = idx +1
  endwhile
  if has_key(d, path[-1])
    return library#EvalLazy(d[path[-1]])
  else
    exec default
  endif
endfunction

fun! config#GetOrSet(name, default) 
  if !exists(a:name)
    let {a:name} = a:default
  endif
  return {a:name}
endf

" getting / setting global / buffer options
" see GetByPath and SetByPath above
function! config#SetG(path, value)
  return config#SetByPath(config#GetOrSet('g:tovl',{}), a:path, a:value)
endfunction
function! config#GetG(...)
  return call(function('config#GetByPath'), [config#GetOrSet('g:tovl',{})] + a:000)
endfunction
function! config#SetB(path, value)
  return config#SetByPath(config#GetOrSet('b:tovl',{}), a:path, a:value)
endfunction
function! config#GetB(...)
  return call(function('config#GetByPath'), [config#GetOrSet('b:tovl',{})] + a:000)
endfunction

function! config#EvalFirstLine(a)
  return eval(a:a[0])
endfunction

" returns cached configuration file (use config#Get to get options)
function! config#ConfigContents(file)
  try
    return config#ScanIfNewer(a:file,
          \ {'fileCache' : 0, 'asLines' : 1, 'scan_func' : function('config#EvalFirstLine'),
          \  'useCached' : config#GetG(['config','dirty',a:file],0),
          \  'default' : ["{}"]
          \ })
  catch /.*/
    return {}
  endtry
endfunction

" configuration is 
function! config#Get(path, ...)
  let configs = config#GetG('config#files')
  let path = config#Path(a:path)
  for file in reverse(copy(configs))
    if filereadable(file)
      " only reread config when all changes have been flushed
      let cache = config#ConfigContents(file)
      try
        let V2 = call(function('config#GetByPath'), [cache, path] + a:000)
        if exists('V')
          " merge
          try
            if (!exists('M'))
              let M = config#GetG(['config']+path+['merge'])
            endif
            let V = library#Call(M, [V, V2]) " merge values, continue
          catch /.*/
            return V " no merge func specified
          endtry
        else
          let V = V2
        endif
        unlet V2
      catch /.*/
      endtry
    endif
  endfor
  if exists('V')
    return V
  else
    if a:0 > 0
      return a:1
    else
      throw "no default value given, config#Get, path: ".string(a:path)
  endif
endfunction

" set a configuration value
" file: The configuration file to make the change
" After changing the configuration it will be saved to disk
" unless you've called config#StopFlushing
" This way you can use multiple vim instances without one overriting
" changes made by another
function! config#Set(path, value, ...)
  " little bit hacky: modify the scan and cache file cached configuration
  " directly:
  exec library#GetOptionalArg('file', "config#GetG('config.files')[0]")
  let p = ['scanned_files',string(function('config#EvalFirstLine')),file,"scan_result"]
  let d = config#GetG(p, {'default' : {}, 'set' :1})
  call config#SetByPath(d, a:path, a:value)
  if !config#FlushConfig(file, 1)
    call config#SetG(['config','dirty',file],1)
  endif
endfunction

function! config#StopFlushing(configFile)
  let p = ['config','noAutoFlush', a:configFile] 
  call config#SetG(p,config#GetG(p, 0) + 1)
endfunction

function! config#ResumeFlushing(configFile)
  let p = ['config','noAutoFlush', a:configFile] 
  call config#SetG(p,config#GetG(p, 0) - 1)
  call config#FlushConfigs()
endfunction

function! config#FlushConfigs()
  for c in config#GetG('config#files') | call config#FlushConfig(c,0) | endfor
endfunction

function! config#FlushConfig(configFile, assumeDirty)
  let dirtyP = ['config','dirty',a:configFile]
  if (a:assumeDirty || config#GetG(dirtyP, 0))
        \ && config#GetG(['config','noAutoFlush',a:configFile],0) == 0
    " flush file (TODO)
    let p = ['scanned_files',string(function('config#EvalFirstLine')),a:configFile,"scan_result"]
    if -1 == writefile([string(config#GetG(p, {'default' : {}}))], a:configFile)
      echoe "flushing configuration file ".a:configFile." failed!"
    else
      call config#SetG(dirtyP, 0)
      call config#FireEvent('config#onChange')
    endif
    return 1
  else
    " indicate that config has not been flushed
    return 0
  endif
endfunction

"|pl    " clear cache
"|      command! ClearScanAndCacheFileCache :call ClearScanAndCacheFileCache()
"|TODO add command to clear cache.. because it will grow and grow.

" opts: scan_func: This function will be applied before returning contents
"       fileCache: write the result to a file (default no)
"       asLines   : if set then read the file and feed file contents into
"                   functions. If not set pass the filename (Maybe you want to
"                   use and external application to process the file)
"       useCached  : don't update file, use cache if already present
"       default: what to return if file doesn't exist
function! config#ScanIfNewer(file, opts)
  let cache = get(a:opts, 'fileCache', 0)
  let file = expand(a:file) " simple kind of normalization. necessary when using file caching
  let Func = get(a:opts, 'scan_func', library#Function('library#Id'))
  let asLines = get(a:opts, 'asLines', 1)
  let func_as_string = string(Func)
  let path = ['scanned_files',func_as_string]
  
  let dict = config#GetG(path, {'set': 1, 'default' : {}})

  if cache
    let cache_file = expand(s:cache_dir.'/'.(a:scan_func, a:file))
    if !has_key(dict, a:file) " try getting from file cache
      if filereadable(cache_file)
        let dict[file] = eval(readfile(cache_file)[0])
      endif
    endif
  endif
  if has_key(dict, a:file)
    " return cached value if up to date
    if get(a:opts, 'useCached', 0)
          \ || getftime(a:file) <= dict[a:file]['ftime']
      return dict[a:file]['scan_result']
    endif
  endif
  if asLines
    try 
      let contents = readfile(a:file)
    catch /.*/
      if has_key(a:opts,'default')
        let contents = a:opts['default']
      else
        throw "ScanIfNewer: Could'n read file ".a:file." error: ".v:exception
      endif
    endtry
    let scan_result = library#Call(Func, [contents])
  else
    let scan_result = library#Call(Func, [a:file])
  endif
  let  dict[a:file] = {"ftime": getftime(a:file), "scan_result": scan_result }
  if cache
    " call vl#lib#files#filefunctions#WriteFile([string(dict[a:file])], cache_file)
  endif
  return scan_result
endfunction

function! s:CacheFileName(scan_func, file)
  " TODO tidy up this function, maybe remvoe it
  let f=vl#lib#files#filefunctions#FileHashValue(string(a:scan_func).a:file)
  let l = min([len(f), 100])
  return strpart(f, len(f) - l, l)
endfunction

function! config#ClearScanAndCacheFileCache()
  " TODO: tidy up
  call vl#lib#files#filefunctions#RemoveDirectoryRecursively(s:cache_dir)
  unlet g:scanned_files
endfunction


" =========== config user interface ==================================
" There is one function handling serializing, and parsing of config values
" for each vim (or custom) type
" toBuffer returns a string list
" fromBuffer takes a string list and returns the value

let s:indent = '  ' " two spaces
function! config#Indent()
  return s:indent " export value
endfunction

" setup default types which can be edited in the configuration editor
" usage: let d = config#GetG('config.types')
" This function is only used to set up the basic types on startup
function! config#DefaultTypes()
  let d = {}
  let d['0'] = config#Number()
  let d['1'] = config#String()
  let d['2'] = config#Funcref() " will be serialized as FakedFunctionReference
  let d['3'] = config#List()
  let d['4'] = config#Dictionary()
  let d['5'] = config#Float()
  let d[4434] = config#FakedFunctionReference()
  "let d['lazy_evaluation'] TODO
  return d
endfunction

function! config#ToBuffer(sp,ind,v)
  let d = config#GetG('config#types')
  return d[library#Type(a:v)]['toBuffer'](a:sp,a:ind,a:v)
endfunction

" lines: the lines of the buffer to be parsed
" idx: current line to be parsed
" currInd: indent to be ignored of the current line (eg after "    key :" of '    key :string "foobar"'
" sp: the spacing indent
" ind: indent of all following lines to be ignored
" FromBuffer is expected to return [idx, configuration value] or to throw an error
function! config#FromBuffer(lines, idx, currInd, sp, ind)
  let d = config#GetG('config#types')
  let fs =  map(values(d),'v:val["fromBuffer"]')
  return library#Try(fs, a:lines, a:idx, a:currInd, a:sp, a:ind)
endfunction

" helper function
function! s:PrefixMatch(p,l)
  let le = len(a:p)
  if a:p == a:l[: le-1]
    return a:l[le :]
  else
    throw a:p."expected, but got ".string(a:l)
  endif
endfunction

function! config#Number()
  let d = {}
  function d.toBuffer(sp,ind,n)
    return ['number='.a:n ]
  endfunction
  function d.fromBuffer(lines, idx, currInd, sp, ind)
    return [a:idx+1, 1*s:PrefixMatch('number=', a:lines[a:idx][(a:currInd):])]
  endfunction
  return d
endfunction

function! config#Float()
  let d = {}
  function d.toBuffer(sp,ind,f)
    return ['float='.string(a:f)]
  endfunction
  function d.fromBuffer(lines, idx, currInd, sp, ind)
    return [a:idx+1, 1*s:PrefixMatch('float=', a:lines[a:idx][(a:currInd):])]
  endfunction
  return d
endfunction

function! config#String()
  let d = {}
  function d.toBuffer(sp,ind,s)
    let lines = split(a:s,"\n")
    if empty(lines)
      return ['string=']
    elseif len(lines) == 1
      return ['string='.lines[0]]
    else
      return ['string='] + map(lines, string(a:ind.a:sp).'.v:val')
    endif
  endfunction
  function d.fromBuffer(lines, idx, currInd, sp, ind)
    let rest = s:PrefixMatch('string=', a:lines[a:idx][(a:currInd):])
    let idx = a:idx +1
    let next_ind = a:ind.a:sp
    if idx < len(a:lines) && a:lines[idx][:len(next_ind)-1] == next_ind
      " multiple lines
      let lines2 = []
      while idx < len(a:lines) && a:lines[idx][:len(next_ind)-1] == next_ind
        call add(lines2, a:lines[idx][len(next_ind):])
        let idx = idx+1
      endwhile
      return [idx, join(lines2, "\n")]
    else
      return [idx, rest]
    endif
  endfunction
  return d
endfunction

" you should use a faked_function_reference. see library#Function()
" that's why I convert real function references to faked ones
function! config#Funcref()
  let d = {}
  let d['toBuffer'] = config#FakedFunctionReference()['toBuffer']
  function!  d.fromBuffer(...)
    call assert#Bool(0, 'this function config#Funcref d.fromBuffer should never be reached')
  endfunction
  return d
endfunction

function! s:ListHelper(ind,valueList)
  let a:valueList[0] = a:ind.a:valueList[0]
  return a:valueList
endfunction

function! config#List()
  let d = {}
  function! d.toBuffer(sp, ind, l)
    let new_ind = string(a:ind.a:sp)
    return ['list='] + tovl#list#Concat(
          \ map(copy(a:l), 's:ListHelper('.new_ind.',config#ToBuffer('.string(a:sp).','.new_ind.',v:val))'))
  endfunction
  function d.fromBuffer(lines, idx, currInd, sp, ind)
    let rest = s:PrefixMatch('list=', a:lines[a:idx][(a:currInd):])
    if rest != ''
      throw "no characters expected after list="
    endif
    let idx = a:idx +1
    let next_ind = a:ind.a:sp
    if idx < len(a:lines) && a:lines[idx][:len(next_ind)-1] == next_ind
      " multiple lines
      let items = []
      while idx < len(a:lines) && a:lines[idx][:len(next_ind)-1] == next_ind
        let [idx, item] = config#FromBuffer(a:lines, idx, len(next_ind), a:sp, next_ind)
        call add(items, item)
      endwhile
      return [idx, items]
    else
      return [idx, []]
    endif
  endfunction
  return d
endfunction

function! s:DictionaryHelper(ind, key, valueList)
  let key = config#KeyToString(a:key)
  if len(a:valueList) == 1
    return [a:ind.key.':'.a:valueList[0]]
  else
    return [a:ind.key.':'.a:valueList[0]] + a:valueList[1:]
  endif
endfunction

function! s:ParseKey(line, ind)
  let i = a:ind
  let key = ''
  while a:line[i] != ":" && i < len(a:line)
    if a:line[i] == '\'
      " escaped char \ or :"
      let i = i+1
    endif
    let key .= a:line[i]
    let i = i+1
  endwhile
  if i > len(a:line)
    throw ': after key of dictionary expected. End of line found instead'
  endif
  return [key, i +1]
endfunction

function! config#Dictionary()
  let d = {}
  function! d.toBuffer(sp, ind, l)
    let new_ind = a:ind.a:sp
    let res = []
    for k in sort(keys(a:l))
      call extend(res, s:DictionaryHelper(new_ind, k, config#ToBuffer(a:sp,new_ind,a:l[k])))
    endfor
    return ['dictionary='] + res
  endfunction
  function d.fromBuffer(lines, idx, currInd, sp, ind)
    let rest = s:PrefixMatch('dictionary=', a:lines[a:idx][(a:currInd):])
    if rest != ''
      throw "no characters expected after dictionary="
    endif
    let idx = a:idx +1
    let next_ind = a:ind.a:sp
    let d = {}
    " multiple keys ?
    while idx < len(a:lines) && a:lines[idx][:len(next_ind)-1] == next_ind
      let [key, curInd] = s:ParseKey(a:lines[idx], len(next_ind))
      let [idx, v] = config#FromBuffer(a:lines, idx, curInd, a:sp, next_ind)
      let d[key] = v
      unlet v
    endwhile
    return [idx, d]
  endfunction
  return d
endfunction

function! config#FakedFunctionReference()
  let d = {}
  function d.toBuffer(sp, ind, f)
    return ['faked_function_reference='.string(a:f)]
  endfunction
  function d.fromBuffer(lines, idx, currInd, sp, ind)
    return [a:idx+1, eval(s:PrefixMatch('faked_function_reference=', a:lines[a:idx][(a:currInd):]))]
  endfunction
  return d
endfunction

"helper function. If there are special chars then serialize
function! config#KeyToString(s)
  return escape(a:s, ':\')
endfunction

" depreceated: only kept in case you'd like to edit only subdictionaries..
" opts is a dictionary with these keys:
" onWrite: function reference beeing called to save data
" getData:  function reference beeing called to provide data to update the view
"         it will be called when the user only uses :w to update the view
"         This is useful because plugins can add default settings in the
"         onSave callback
" TODO implement completion etc
function! config#EditConfiguration(opts)
  let a:opts['name'] = get(a:opts, 'name', 'config')
  let a:opts['help'] = help
  let a:opts['getContent'] = library#Function(
            \ "return config#ToBuffer(".string(s:indent).", '',library#Call(".string(a:opts['getData'])."))")

  call tovl#scratch_buffer#ScratchBuffer(a:opts)
  " tweak buffer
  "syntax:
  " TODO improve syntax highlighting!
  setlocal filetype=tovl_config
endfunction

" uses config#EditConfiguration to open a scratch buffer in which you can edit
" the cached configuration files.
" if you don't pass the file to be edited a list will be shown to let you
" choose one
function! config#EditConfig(...)
  exec library#GetOptionalArg('file', "tovl#ui#choice#LetUserSelectIfThereIsAChoice('choose the config file to edit', config#GetG('config#files'))")
  let file = config#GetG('config#files')[0]
  exec 'e tovl_config://'.file
  return 
endfunction

function! config#EditConfigWrite(file)
  let p = ['scanned_files',string(function('config#EvalFirstLine')),a:file,"scan_result"]
  let lines = getline(0,line('$'))
  call config#StopFlushing(a:file)

  call config#SetG(p, config#FromBuffer(lines,0,0, '  ','')[1])
  if a:file == config#GetG('config#files')[0]
    " editing main config, reload plugins
    call tovl#plugin_management#UpdatePlugins()
  endif
  call config#ResumeFlushing(a:file)
  if !config#FlushConfig(a:file, 1)
    call config#SetG(['config','dirty',a:file],1)
  endif
  setlocal nomodified
endfunction

function! config#EditConfigGetData(file)
  if a:file == config#GetG('config#files')[0]
    call config#StopFlushing(a:file)
    
    let cfgDict = config#ConfigContents(a:file)
    call config#GetByPath(cfgDict, 'loadablePlugins', {'set' : 1, 'default' : {}})
    " editing main config,
    " ask plugins to add their default options.
    let toload = tovl#plugin_management#PluginsFromDict([],cfgDict['loadablePlugins'],"v > 0")
    for pl in toload
      try
        let p = tovl#plugin_management#PluginDict(pl)
        if (has_key(p, 'AddDefaultConfigOptions'))
          call library#Call(p['AddDefaultConfigOptions'],[cfgDict],p)
        endif
      catch /.*/
        echom "plugin ".pl." threw an exception while adding defaults:".v:exception
      endtry
    endfor
    " update plugin list.. don't remove user stuff
    let d = tovl#plugin_management#TidyUp(
          \ config#GetByPath(cfgDict, 'loadablePlugins', {'default' : {}, 'set' : 1}))
    call config#ResumeFlushing(a:file)
  endif
  return config#ConfigContents(a:file)
endfunction

augroup TOVLWrite
augroup end

fun! config#TOVLConfigReadCmd()
  " Why doesn't the autocmmand work?
  setlocal ft=tovl_config
  command! DiffDefaults :diffsplit tovl_config_default

  let file = matchstr(expand('%'), 'tovl_config://\zs.*')
  call append(0, config#ToBuffer(s:indent, '',config#EditConfigGetData(file)))
  command! -buffer Help :h 
  echo " "
  echo '>> use :h tovl-config-buffer to get more information (core/doc/tovl-config-buffer.txt)'
endf

fun! config#TOVLConfigDefaultReadCmd()
  setlocal ft=tovl_config
  let cfgDict = {}
  let loaded = config#GetG('tovl#plugins#loaded',{ 'default' : {}, 'set' :1})
  for p in values(loaded)
    if (has_key(p, 'AddDefaultConfigOptions'))
      call library#Call(p['AddDefaultConfigOptions'],[cfgDict],p)
    endif
  endfor
  call append(0, config#ToBuffer(s:indent, '',cfgDict))
endf

fun! config#TOVLConfigWriteCmd()
  let file = matchstr(expand('%'), 'tovl_config://\zs.*')
  call config#EditConfigWrite(file)
  echo ">> config written, now use :e! % to refresh contents"
endf

fun! config#Fold(lnum)
  let curr=indent(a:lnum)/2
  if v:lnum == line('$')
    return curr
  else
    let next = indent(a:lnum+1)/2
    if next > curr
      return curr +1
    endif
    return curr
endf
