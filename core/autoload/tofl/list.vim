function! tofl#list#Concat(list_of_lists)
  let result = []
  for l in a:list_of_lists
    call extend(result, l)
  endfor
  return result
endfunction

" returns the items beeing contained only in and not in b (might be slow)
function! tofl#list#Difference(a,b)
  let result = []
  for i in a:a
    if index(a:b, i) == -1
      call add(result, i)
    endif
  endfor
  return result
endfunction
