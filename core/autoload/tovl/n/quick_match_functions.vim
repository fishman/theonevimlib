"" brief-description : match a omni completion entry by less characters
"" keywords : omnicompletion 
"" author : Marc Weber marco-oweber@gmx.de
"" started on :2006 Oct 03 02:24:20
"" version: 0.1
"" 
""  proposed-usage:
""  ==============
"" vl/dev/haskell/modules_list_cache_jump.vim uses it.

" replaces upper characters C with C\u*\U* 
" so Ohh can be matched by O
" and lower characters c with c\U* 
" so ohh can be matched by o
function! tovl#n#quick_match_functions#AdvancedCamelCaseMatching(expr)
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
