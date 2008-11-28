" Many small utility functions
function! library#Id(a)
  return a:a
endfunction

" same as type but supports extra types faked by using special key in
" dictionaries
function! library#Type(a)
  let t = type(a:a)
  if t == 4 && has_key(a:a, 'faked_function_reference')
    return 100
  else
    return t
  fi
endfunction

" args : same as used for call(f,[list], self), f must be a funcref
" vim doesn't handle autoloading yet ;-(
" So let's do that ourselves
function! library#Call(...)
  let t = library#Type(a:1)
  if t == 2
    " funcref: function must have been laoded
    return call(function('call'), a:000)
  elseif t == 100
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
    return call(function('call'), args)
  endif
endfunction

" vim requires that the function has already been loaded
" That's why I'm using a faked function reference type here
function! library#Function(name)
  return { 'faked_function_reference' : a:name }
endfunction
