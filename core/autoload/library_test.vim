function! library_test#Test()
  let m = expand('<sfile>').' '
  call assert#Equal('yes', library#Id('yes'), m.'library#Id')
  call assert#Equal('yes', library#Call(library#Function('library_test#ReferencedFunc'), []), m.'library#Call and Function')
  call assert#Equal('test ok' , library#EvalLazy(library#EvalWhenRequested(library#Function('library_test#EvalLazyValue'))) , m.'EvalWhenRequested+EvalLazyValue')
endfunction

function! library_test#ReferencedFunc()
  return 'yes'
endfunction

function! library_test#EvalLazyValue()
  return "test ok"
endfunction

" call library_test#Test()
