
" blah<cursor>foo will return ["blah","foo"]
fun! tovl#buffer#SplitCurrentLineAtCursor()
  let pos = col('.') -1
  let line = getline('.')
  return [strpart(line,0,pos), strpart(line, pos, len(line)-pos)]
endfunction
