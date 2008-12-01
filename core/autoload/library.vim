" Many small utility functions
function! library#Id(a)
  return a:a
endfunction

" no operation dummy
function! library#NOP()
endfunction

"|p     returns optional argument or default value
"|p     Example usage:
"|p     default is of type string so that it is only evaluated when actually
"|+     needed
"|code  function! F(...)
"|        exec GetOptionalArg('optional_arg',string('no optional arg given'))
"|        exec GetOptionalArg('snd_optional_arg',string('no optional arg given'),2)
"|        echo 'optional arg is '.string(optional_arg)
"|      endfunction
function! library#GetOptionalArg( name, default, ...)
  if a:0 == 1
    let idx = a:1
  else
    let idx = 1
  endif
  if type( a:default) != 1
    throw "wrong type: default parameter of vl#lib#brief#args#GetOptionalArg must be a string, use string(value)"
  endif
  let script = [ "if a:0 >= ". idx
	     \ , "  let ".a:name." = a:".idx
	     \ , "else"
	     \ , "  let ".a:name." = ".a:default
	     \ , "endif"
	     \ ]
  return join( script, "\n")
endfunction

" calls a list of function which may throw exceptions to indicate failure.
" the result of the first suceeding function is returned
function! library#Try(funcList,...)
  let errors=[]
  for F in a:funcList
    try
      return call(function("library#Call"), [F] + a:000)
    catch /.*/
      call add(errors, v:exception)
    endtry
  endfor
  throw "no handler suceeded, errors: ".join(errors, "\n")
endfunction

" =========== special types ==========================================

" vim requires that the function has already been loaded
" That's why I'm using a faked function reference type here
" library#Function("Foo", { 'args' : [2, "foo"], 'self' : dict}) will create a closure. args
" these args + args passed to Call will be the list of args passed to call()
function! library#Function(name,...)
  exec library#GetOptionalArg('d', string({'evalLazyClosedArgs': 1}))
  let d['faked_function_reference'] = a:name
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
" if you add types use a rand value (eg echo $RANDOM) to minimize the chance
" of conflicts
" I would have used strings instead, but 0 == "foo" is 1!
" So the risk of getting this wrong is higher..
function! library#Type(a)
  let t = type(a:a)
  if t == 4 
   if has_key(a:a, 'faked_function_reference')
      return 4434
    elseif has_key(a:a, 'lazy_evaluation')
      return 6057
   endif
  endif
  return t
endfunction

" ============ special types helper functions =========================

function! library#EvalLazy(v)
  if library#Type(a:v) == 6057
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
  let args = copy(a:000)
  if (len(args) < 2)
    call add(args, [])
  endif
  if t == 2
    " funcref: function must have been laoded
    return call(function('call'), args)
  elseif t == 4434
    " pseudo function, let's load it..
    let name = args[0]['faked_function_reference']
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
    if has_key(args[0], 'args') " add args from closure
      if get('args', 'evalLazyClosedArgs', 0)
        let args[1] = map(a[0]['args'], 'library#EvalLazy(v:val)')+args[1]
      else
        let args[1] = a[0]['args']+args[1]
      endif
    endif
    if has_key(args[0], 'self')
      let args[2] = a[0]['self']
    endif
    let args[0] = function(name)
    return call(function('call'), args)
  endif
endfunction
