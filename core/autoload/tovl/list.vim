function! tovl#list#Concat(list_of_lists)
  let result = []
  for l in a:list_of_lists
    call extend(result, l)
  endfor
  return result
endfunction

" returns the items beeing contained only in and not in b (might be slow)
function! tovl#list#Difference(a,b)
  let result = []
  for i in a:a
    if index(a:b, i) == -1
      call add(result, i)
    endif
  endfor
  return result
endfunction

fun! tovl#list#Intersection(a,b)
  let result = []
  for i in a:a
    if index(a:b, i) != -1
      call add(result, i)
    endif
  endfor
  return result
endf

function! tovl#list#AddUnique(list, value)
  if index(a:list, a:value) == -1
    call add(a:list, a:value)
  endif
  return a:list
endfunction

fun! tovl#list#Uniq(list)
  let i = len(a:list)-1
  while i > 0
    if index(a:list, a:list[i]) < i
      call remove(a:list, i)
    endif
    let i = i -1
  endwhile
  return a:list
endf

" remove element from list
fun! tovl#list#Remove(l, i)
  let i = index(a:l, a:i)
  if i >= 0
    call remove(a:l, i)
  endif
endf

" combination of map and filter
function! tovl#list#MapIf(list, pred, expr)
  let result = []
  for Val in a:list
    exec 'let p = ('.a:pred.')'
    exec 'if p | call add(result, '.a:expr.')|endif'
  endfor
  return result
endfunction
