" support for multiple completion functions
" see plugins/completion/choose_completion.vim
"
" a is dict { 'description' : .., 'func' : ... } 
fun! tovl#ui#multiple_completions#RegisterBufferCompletionFunc(a) 
  call tovl#list#AddUnique(config#GetB('completion#functions',{'default' : [], 'set' : 1}),a:a)
  " adding indirection, so that you can use functions created by library#Function
  " containing closed args
  call config#GetB('completion#func', {'default' : a:a, 'set' : 1 })
  setlocal completefunc=tovl#ui#multiple_completions#Complete
endf

fun! tovl#ui#multiple_completions#Complete(...)
  return library#Call(config#GetB('completion#func')['func'],a:000)
endf

fun! tovl#ui#multiple_completions#ChooseCompletionFunc() 
  let functionDicts = config#GetB('completion#functions', [])
  let list = map(copy(functionDicts), 'v:val["description"]')
  let idx = tovl#ui#choice#LetUserSelectIfThereIsAChoice(
    \ 'select completefunc', list, "return index")
  call config#SetB("completion#func", functionDicts[idx])
endf
