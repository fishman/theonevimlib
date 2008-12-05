" replaces upper characters C with C\u*\U* 
" so Ohh can be matched by O
" and lower characters c with c\U* 
" so ohh can be matched by o
" usage example: vimfile.vim (omnicompletion)
function! tovl#ui#match#AdvancedCamelCaseMatching(expr)
  let result = ''
  if len(a:expr) > 10 " vim can't cope with to many \( ? and propably we no longer want this anyway
    return 'noMatchDoh'
  endif
  for index in range(0,len(a:expr))
    let c = a:expr[index]
    if c =~ '\u'
      let result .= c.'\u*\l*_\='
    elseif c =~ '\l'
      let result .= c.'\l*\%(\l\)\@!_\='
    else
      let result .= c
    endif
  endfor
  return '^'.result
endfunction
