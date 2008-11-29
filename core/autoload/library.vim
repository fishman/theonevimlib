" Many small utility functions
function! library#Id(a)
  return a:a
endfunction

" =========== special types ==========================================

" vim requires that the function has already been loaded
" That's why I'm using a faked function reference type here
" library#Function("Foo", { 'args' : [2, "foo"], 'self' : dict}) will create a closure. args
" these args + args passed to Call will be the list of args passed to call()
function! library#Function(name,...)
  if a:0 > 0 then
    let d = a
  else
    d = {}
  endif
  d['faked_function_reference'] = a:name
  return d
endfunction

" can be used with config#SetByPath (thus also with config#SetG)
" When reading the value it will be replaced by the result of the given
" function reference
function! library#EvalWhenRequested(name)
  return { 'lazy_evaluation' : a:name }
endfunction

" same as type but supports extra types faked by using special key in
" dictionaries
" intentionally not using integers for custom types to lessen chance of
" conflicts when merging
function! library#Type(a)
  let t = type(a:a)
  if t == 4 
   if has_key(a:a, 'faked_function_reference')
      return "faked_function_reference"
    elseif has_key(a:a, 'lazy_evaluation')
      return "lazy_evaluation"
   endif
  endif
  return t
endfunction

" ============ special types helper functions =========================

function! library#EvalLazy(v)
  if library#Type(a:v) == 'lazy_evaluation'
    return library#Call(a:v['lazy_evaluation'],[])
  else
    return a:v
  endif
endfunction

" args : same as used for call(f,[list], self), f must be a funcref
" vim doesn't handle autoloading yet ;-(
" So let's do that ourselves
" the last "self" argument can be overriden by the function reference
function! library#Call(...)
  let t = library#Type(a:1)
  if t == 2
    " funcref: function must have been laoded
    return call(function('call'), a:000)
  elseif t == 'faked_function_reference'
    " pseudo function, let's load it..
    let name = a:1['faked_function_reference']
    if !exists('*'.name)
      let file = substitute(substitute(name,'#[^#]*$','',''),'#','/','g')
      for path in split(&runtimepath,',')
        let realfile = path.'/autoload/'.file.'.vim'
        if filereadable(realfile)
          exec 'source '.realfile
          break
        endif
      endfor
    endif
    let args = copy(a:000)
    let args[0] = function(name)
    if a:1['args'] " add args from closure
      let args[1] = a:1['args']+arsg[1]
    endif
    if a:1['self']
      let args[2] = a:1['self']
    endif
    return call(function('call'), args)
  endif
endfunction
