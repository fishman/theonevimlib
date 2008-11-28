" a union way to configure theonelib and  plugins:
"
" SetByPath, GetByPath define functions to set values within hirarchical dicts
" SetG GetG use those to get global settings
" configFiles is the list which will be checked for configuration settigns
" configFilesFunc is the function reference returning this list.
"   You can override it in your .vimrc
"
" if multiple configuration files contains the same value a plugin can specify
" a merge function
" eg call SetG('config.merge.configpath', function(my#MergeLists))
" If you would try to get the option config.merge.configpath.foo.bar
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
function! config#GetByPath(dict, path, ...)
  if a:0 > 0
    let default = 'return a:1'
  else
    let default = 'throw '.string("no default value given, GetByPath path: ".string(a:dict))
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
      return PF(path[idx+1:])
    else
      let d = PF
    endif
    unlet PF
    let idx = idx +1
  endwhile
  if has_key(d, path[-1])
    return d[path[-1]]
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
  let configs = config#GetG('configFiles')
  let path = config#Path(a:path)
  for file in reverse(copy(configs))
    if filereadable(file)
      let cache = config#ScanIfNewer(file, {'fileCache' : 0, 'asLines' : 1, 'scan_func' : function('config#EvalFirstLine')})
      try
        let V2 = call(function('config#GetByPath'), [cache, path] + a:000)
        if exists('V')
          " merge
          try
            if (!exists('M'))
              let M = config#GetG(['config','merge']+path)
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

"|pl    " clear cache
"|      command! ClearScanAndCacheFileCache :call ClearScanAndCacheFileCache()
"|TODO add command to clear cache.. because it will grow and grow.

" opts: scan_func: This function will be applied before returning contents
"       fileCache: write the result to a file (default no)
"       asLines   : if set then read the file and feed file contents into
"                   fucntions. If not set pass the filename (Maybe you want to
"                   use and external application to process the file)
function! config#ScanIfNewer(file, opts)
  let cache = get(a:opts, 'fileCache', 0)
  let file = expand(a:file) " simple kind of normalization. necessary when using file caching
  let Func = get(a:opts, 'scan_func', library#Function('library#Id'))
  let asLines = get(a:opts, 'asLines', 1)
  let func_as_string = string(Func)
  if !exists('g:scanned_files')
    let g:scanned_files = {}
  endif
  if !has_key(g:scanned_files, func_as_string)
    let g:scanned_files[func_as_string] = {}
  endif
  let dict = g:scanned_files[func_as_string]
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
    if getftime(a:file) <= dict[a:file]['ftime']
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