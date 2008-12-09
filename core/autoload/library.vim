" Many small utility functions
function! library#Id(a)
  return a:a
endfunction

" no operation dummy
" useful eg for start debugging this way
function! library#NOP(...)
endfunction

" FIXME: Is there a better way to execute multi line strings?
function! library#Exec(cmd)
  let lines = split(a:cmd,"\n")
  if (len(lines) > 1)
    " is there a better way? (TODO! try to not use temp files!)
    let file = tempname()
    call writefile(lines, file)
    exec 'source '.file
    call delete(file)
  elseif !empty(lines)
    exec lines[0]
  endif
endfunction

" returns a function reading the given file when called
function! library#ReadLazy(f,...)
  let opts = a:0 > 0 ? a:1 : {}
  if get(opts, 'join',0)
    return library#EvalWhenRequested(library#Function('return join(readfile('.string(a:f).'),"\n")'))
  else
    return library#EvalWhenRequested(library#Function('return readfile('.string(a:f).')'))
  endif
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
"|
"|  note: probably this function will be replaced.
"|  let arg = a:0 > 0 ? a:1 : default or TVarArg should be prefered.. (TODO:
"|   cleanup code!)
function! library#GetOptionalArg( name, default, ...)
  if a:0 == 1
    let idx = a:1
  else
    let idx = 1
  endif
  if type( a:default) != 1
    throw "wrong type: default parameter of vl#lib#brief#args#GetOptionalArg must be a string, use string(value)"
  endif
  let script = [ "if a:0 >= ". idx." "
	     \ , "  let ".a:name." = a:".idx." "
	     \ , " else "
	     \ , "  let ".a:name." = ".a:default." "
	     \ , " endif "
	     \ ]
  return join( script, "|")
endfunction

" calls a list of function which may throw exceptions to indicate failure.
" the result of the first suceeding function is returned
function! library#Try(funcList,...)
  let errors=[]
  " using idx here to not get E705
  for idx in range(0,len(a:funcList)-1)
    try
      return call(function("library#Call"), [a:funcList[idx]] + [a:000])
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
  let d = a:0 > 0 ? a:1 : {}
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
  " always pass self. this way you can call functions from dictionaries not
  " refering to self
  if (len(args) < 3)
    call add(args, {})
  endif
  if t == 2
    " funcref: function must have been laoded
    return call(function('call'), args)
  elseif t == 4434
    let Fun = args[0]['faked_function_reference']
    if type(Fun) == 1 
        \ && (Fun[:len('return ')-1] == 'return ' 
              \ || Fun[:len('call ')-1] == 'call '
              \ || Fun[:len('if ')-1] == 'if ')
      " function is a String, call exec
      let ARGS = args[1]
      let SELF = args[2]
      exec Fun
    else 
      " pseudo function, let's load it..
      if type(Fun) == 1
        if !exists('*'.Fun)
          let file = substitute(substitute(Fun,'#[^#]*$','',''),'#','/','g')
          for path in split(&runtimepath,',')
            let realfile = path.'/autoload/'.file.'.vim'
            if filereadable(realfile)
              exec 'source '.realfile
              break
            endif
          endfor
        endif
        let Fun2 = function(Fun)
      else
        let Fun2 = Fun
      endif
      if has_key(args[0], 'args') " add args from closure
        if get(args[0], 'evalLazyClosedArgs', 1)
          let args[1] = map(args[0]['args'], 'library#EvalLazy(v:val)')+args[1]
        else
          let args[1] = args[0]['args']+args[1]
        endif
      endif
      if has_key(args[0], 'self')
        let args[2] = args[0]['self']
      endif
      let args[0] = Fun
      return call(function('call'), args)
    endif
  else
    " no function, return the value
    return args[0]
  endif
endfunction
