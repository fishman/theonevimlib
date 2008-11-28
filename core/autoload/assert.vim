function! assert#Msg(msg)
  return "assertion failed :".a:msg
endfunction

function! assert#Bool(b,msg)
  if (!a:b)
    throw assert#Msg(a:msg)
  endif
endfunction

function! assert#Equal(a,b,msg)
  if library#Type(a:a) != library#Type(a:b) || a:a != a:b
    throw assert#Msg(' not equal : '.string(a:a).' and '.string(a:b).' '.a:msg)
  endif
endfunction
