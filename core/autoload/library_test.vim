function! library_test#Test()
  call assert#Equal('yes', library#Id('yes'), 'library#Id')
  call assert#Equal('yes', library#Call(library#Function('library_test#ReferencedFunc'), []), 'library#Call and Function')
endfunction

function! library_test#ReferencedFunc()
  return 'yes'
endfunction
