" script-purpose: find text with left opened brackets/ .... used in my
" contextcompletion ftpplugin-scripts using vl#textediting#contextcompletion
" author: Marc Weber
" started : Sat Sep 16 08:04:31 CEST 2006
" stabilitiy : usable
" description: Do not just add a tag to the currrent file but to all files of
" the same type and those who will be opened in the  future using

" returns regular regex which matches arbitrary amount of 
" (outer* open inner* close outer*)* outer* open inner
function! tovl#regex#regex#MatchLeftOpen(open,close,inner,outer)
  return '\%('.a:outer.'*'.a:open.a:inner.'*'.a:close.'\)*'.a:outer.'*'.a:open.a:inner.'*'
endfunction
" vl#lib#regex#regex#OpenCloseManyTimes(<,>,a,b,1) matches <aaa>bbbb<a>b
function! tovl#regex#regex#OpenCloseManyTimes(open,close,inner,outer,includeLeadingOuter, includeTrailingOuter)
  return vl#lib#brief#conditional#IfElse(a:includeLeadingOuter,a:outer.'*','')
	\ .'\%('.a:outer.'*'.a:open.a:inner.'*'.a:close.'\)\='
	\ .vl#lib#brief#conditional#IfElse(a:includeTrailingOuter,a:outer.'*','')
endfunction
" matches "sdf"..."sdfkj".."slfdj\"k"
function! tovl#regex#regex#ManyQuotedStrings(notOuterSet, includeLeadingOuter, includeTrailingOuter)
  let openclose='"'
  let inner='\%([^"]\|\\"\)'
  return tovl#regex#regex#OpenCloseManyTimes(openclose,openclose,inner,'[^"'.a:notOuterSet.']',a:includeLeadingOuter,a:includeTrailingOuter)
endfunction

" matches "blah..\ but not "blah"
function! tovl#regex#regex#MatchLeftOpenQuotedString()
  let openclose='\%(\\\@<!"\)'
  let inner='\%([^"]\|\\"\)'
  return tovl#regex#regex#MatchLeftOpen(openclose,openclose,inner,'[^"]')
endfunction

"|func returns regular expression which matches many regex seperated by
"|+    separator
function! tovl#regex#regex#SeperatedBy(regex, separator)
  return '\%('.a:regex.a:separator.'\)*'.a:regex
endfunction

"function! MatchEvenNumber(matchItem,inner,outer)
"endfunction

"|func returns a list of all matches of the regex
function! tovl#regex#regex#MatchAll(str, regex)
  let matches = []
  let s = a:str
  while 1
    let pos = match(s,a:regex)
    if pos == -1 
      return matches
    else
      let match = matchstr(s, a:regex)
      call add(matches, match)
      let s = strpart(s,strlen(match)+pos)
    endif
  endwhile
endfunction
