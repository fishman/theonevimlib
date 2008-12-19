" helpers for creating mappers

" usage: inoremap <m-=> <c-r>=tovl#map#SurroundBy(' ','=',' ')<cr>
" This will add leading and trailing white spaces if not present
" memomic: Insert L eading T railing text as well
fun! tovl#map#InsertLT(before, text, after)
  let [b,a] = tovl#buffer#SplitCurrentLineAtCursor()
  return (a =~ a:before.'$' ? '' : a:before ).a:text.(b =~ '^'.a:after ? '' : a:after )
endf
