function! tofl#list#Concat(list_of_lists)
  let result = []
  for l in a:list_of_lists
    call extend(result, l)
  endfor
  return result
endfunction
