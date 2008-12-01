" a union way to configure theonelib and  plugins:
"
" SetByPath, GetByPath define functions to set values within hirarchical dicts
" SetG GetG use those to get global settings (you know about (deep)copy() ?)
" configFiles is the list which will be checked for configuration settings
" configFilesFunc is the function reference returning this list.
"   You can override it in your .vimrc
"
" if multiple configuration files contains the same value a plugin can specify
" a merge function
" eg call SetG('config.configpath.merge', function(my#MergeLists))
" If you would try to get the option config.configpath.foo.bar.merge
" ['foo','bar'] would be fed into my#MergeLists which should return a merge
" function itself

" To read or write configuration options use
" config#Get(path, default) 
" config#Set(path, value)
" config#Set(path, value, {'write': 0} ) # to not force writing the changed config to disk.
"   This increases performance if you wnat to set many settings at once
"   After having changed the configs use config#WriteConfigs() to flush contents
function! config#Path(path)
  if type(a:path) == 1
    return split(a:path,'\.')
  else 
    return a:path
  endif
endfunction

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

function! config#DefaultConfigFiles()
  " adding per directory project configuration files would be cool.
  " But maybe this is bad for security? Ask the user once and store md5sum?
  return [expand('HOME').'/.theonevimlib_config']
endfunction

" if foo.bar is set to a function ref that will be passed the remaining path
" and its result is returned
" usage example: GetByPath('foo.bar', {'set' : 1, 'default' : {}})
" GetByPath('foo', 2) shortcut for GetByPath('foo',{'default' : 2})
" will return setting foo.bar and set it to the default value {} if it hasn't been set yet
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
      let default = 'call config#SetG(a:path, opts["default"])|'.default
    endif 
  else
    let default = 'throw '.string("no default value given, GetByPath path: ".string(a:path))
  endif
  let path = config#Path(a:path)
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

function! config#TOVL()
  if !exists('g:tovl')
    let g:tovl = {}
  endif
  return g:tovl
endfunction

" a#SetG('foo.bar', 7) is equal to a#SetG(['foo','bar'], 7)
function! config#SetG(path, value)
  return config#SetByPath(config#TOVL(), a:path, a:value)
endfunction

" args: GetG(path) " throws exception if path doesn't exist
"    or GetG(path, default)
function! config#GetG(...)
  return call(function('config#GetByPath'), [config#TOVL()] + a:000)
endfunction

function! config#EvalFirstLine(a)
  return eval(a:a[0])
endfunction

" configuration is 
function! config#Get(path, ...)
  let configs = config#GetG('config.configFiles')
  let path = config#Path(a:path)
  for file in reverse(copy(configs))
    if filereadable(file)
      " only reread config when all changes have been flushed
      let cache = config#ScanIfNewer(file, 
        \ {'fileCache' : 0, 'asLines' : 1, 'scan_func' : function('config#EvalFirstLine'),
           \ 'useCached' : config#GetG(['config','dirty',file],0)
        \ })
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
function! config#Set(file, path, value)
  " little bit hacky: modify the scane and cache file cached configuration
  " directly:
  let p = ['scanned_files',string(function('config#EvalFirstLine')),a:file,"scan_result"]
  let d = config#GetG(p, {'default' : {}, 'set' :1})
  call config#SetByPath(d, a:path, a:value)
  if !config#FlushConfig(a:file, 1)
    call config#SetG(['config','dirty',a:file],1)
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
  for c in config#GetG('config.configFiles') | call config#FlushConfig(c,0) | endfor
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
    let scan_result = library#Call(Func, [readfile(a:file)])
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

let s:indent = ' |' " two spaces
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
  let d['2'] = config#Funcref()
  let d['3'] = config#List()
  let d['4'] = config#Dictionary()
  let d['5'] = config#Float()
  let d[6057] = config#FakedFunctionReference()
  "let d['lazy_evaluation'] TODO
  return d
endfunction

function! config#ToBuffer(sp,ind,v)
  let d = config#GetG('config.types')
  return d[library#Type(a:v)]['toBuffer'](a:sp,a:ind,a:v)
endfunction

" lines: the lines of the buffer to be parsed
" idx: current line to be parsed
" currInd: indent to be ignored of the current line (eg after "    key :" of '    key :string "foobar"'
" sp: the spacing indent
" ind: indent of all following lines to be ignored
" FromBuffer is expected to return [idx, configuration value] or to throw an error
function! config#FromBuffer(lines, idx, currInd, sp, ind)
  let d = config#GetG('config.types')
  let fs =  map(values(d),'v:val["fromBuffer"]')
  return library#Try(fs, lines, idx, currInd, sp, ind)
endfunction

" helper function
function! s:PrefixMatch(p,l)
  let le = len(a:p)
  if a:p == a:l[:le]
    return a:l[le+1:]
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
    return [a:idx+1, 1*s:PrefixMatch('number=', lines[a:idx][a:currInd:])]
  endfunction
  return d
endfunction

function! config#Float()
  let d = {}
  function d.toBuffer(sp,ind,f)
    return ['float='.string(a:f)]
  endfunction
  function d.fromBuffer(lines, idx, currInd, sp, ind)
    return [a:idx+1, 1*s:PrefixMatch('float=', lines[a:idx][a:currInd:])]
  endfunction
  return d
endfunction

function! config#String()
  let d = {}
  function d.toBuffer(sp,ind,s)
    let lines = split(a:s,"\n")
    if len(lines) > 1
      return ['string='] + map(lines, string(a:ind.a:sp).'.v;val')
    else
      return ['string='.lines[0]]
    endif
  endfunction
  function d.fromBuffer(lines, idx, currInd, sp, ind)
    let rest = 1*s:PrefixMatch('string=', lines[a:idx][a:currInd:])
    let idx = a:idx +1
    if lines[idx][:len(a:ind)] == a:ind
      " multiple lines
      let lines = []
      while lines[idx][:len(a:ind)] == a:ind
        call add(lines, lines[idx][len(a:ind)+1:])
        let idx = idx+1
      endwhile
      return [idx, join(lines, "\n")]
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
    call assert#Bool(false, 'this function config#Funcref d.fromBuffer should never be reached')
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
    return ['list='] + tofl#list#Concat(
          \ map(copy(a:l), 's:ListHelper('.new_ind.',config#ToBuffer('.string(a:sp).','.new_ind.',v:val))'))
  endfunction
  function d.fromBuffer(lines, idx, currInd, sp, ind)
    let rest = 1*s:PrefixMatch('list=', lines[a:idx][a:currInd:])
    if rest != ''
      throw "no characters expected after list="
    endif
    let idx = a:idx +1
    let next_ind = a:ind.a:sp
    if lines[idx][:len(a:ind)] == a:ind
      " multiple lines
      let items = []
      while lines[idx][:len(a:ind)] == a:ind
        let [idx, item] = config#FromBuffer(a:lines, idx, len(ind), a:sp, next_ind)
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
  while a:line[i] != ":" and i < len(a:line)
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
  return [key, i]
endfunction

function! config#Dictionary()
  let d = {}
  function! d.toBuffer(sp, ind, l)
    let new_ind = string(a:ind.a:sp)
    return ['dictionary='] + tofl#list#Concat(
        \ values(map(copy(a:l), 's:DictionaryHelper('.new_ind.',v:key, config#ToBuffer('.string(a:sp).','.new_ind.',v:val))')))
  endfunction
  function d.fromBuffer(lines, idx, currInd, sp, ind)
    let rest = 1*s:PrefixMatch('dictionary=', lines[a:idx][a:currInd:])
    if rest != ''
      throw "no characters expected after dictionary="
    endif
    let idx = a:idx +1
    let next_ind = a:ind.a:sp
    if lines[idx][:len(a:ind)] == a:ind
      " multiple lines
      let d = {}
      while lines[idx][:len(a:ind)] == a:ind
        let [key, curInd] = s:ParseKey(a:lines[idx], len(ind))
        let [idx, v] = config#FromBuffer(a:lines, idx, curInd, a:sp, next_ind)
        let d[key] = v
      endwhile
      return [idx, d]
    else
      return [idx, {}
    endif
  endfunction
  return d
endfunction

function! config#FakedFunctionReference()
  let d = {}
  function d.toBuffer(f)
    return ['faked_function_reference='.string(f)
  endfunction
  function d.fromBuffer(lines, idx, currInd, sp, ind)
    return [a:idx+1, eval(s:PrefixMatch('faked_function_reference=', lines[a:idx][a:currInd:]))]
  endfunction
  return d
endfunction

"helper function. If there are special chars then serialize
function! config#KeyToString(s)
  return escape(a:s, ":\")
endfunction

" opts is a dictionary with these keys:
" onWrite: function reference beeing called to save data
" getData:  function reference beeing called to provide data to update the view
"         it will be called when the user only uses :w to update the view
"         This is useful because plugins can add default settings in the
"         onSave callback
" TODO implement completion etc
function! config#EditConfig(opts)
  let name = get(a:opts, 'name', 'config')
  call tofl#buffer#ScratchBuffer({
        \ 'name' : name,
        \ 'header': [ 'edit configuration '.name,
                    \ 'use ZZ or :w to save the configuration, :Refresh to refresh it',
                    \ 'refresh will take place automatically after writing'],
        \ 'content' : config#ToBuffer(s:indent, '', library#Call(a:opts['getData'])),
        \ 'onWrite' : a:opts['onWrite'] })
endfunction

augroup TOVLWrite
augroup end
