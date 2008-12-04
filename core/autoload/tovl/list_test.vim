function! tofl#list_test#Test()
  let m = expand('<sfile>').' '
  call assert#Equal(tofl#list#Concat([[1],[2]]), [1,2], m.'list#Concat')
endfunction
