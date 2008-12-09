" let the user pick an item from a list
" this should be replaced by a TToC like implementation

let s:use_getchar =1

"|func  returns: item by default
"|      optional parameter: "return index" to return the index instead of the value
"|                          "return both" t return both ([index,item]  [-1,""] in case of no selection )
function! tovl#ui#choice#LetUserSelectOneOf(caption, list, ...)
  let list_to_show = [a:caption]
  " add numbers
  for i in range(1,len(a:list))
    call add(list_to_show, i.') '.a:list[i-1])
  endfor
  let index = tovl#ui#choice#Inputlist(list_to_show)
  if index == 0
    let result = [ -1,  ""]
  else 
    let result = [index -1, a:list[index -1] ]
  endif
  if a:0 > 0
    if a:1 == "return index"
      return result[0] " return index
    else
      return result " return both
    endif
  else
    return result[1] "return item
  endif
endfunction

"|func if list contains more than one item let the user select one
"|     else return the one item
function! tovl#ui#choice#LetUserSelectIfThereIsAChoice(caption, list, ...)
  if len(a:list) == 0
    throw "LetUserSelectIfThereIsAChoice: list has no elements"
  elseif len(a:list) == 1
    return a:list[0]
  else
    if a:0 > 0 
      return tovl#ui#choice#LetUserSelectOneOf(a:caption, a:list, a:1)
    else
      return tovl#ui#choice#LetUserSelectOneOf(a:caption, a:list)
  endif
endfunction


function! tovl#ui#choice#Inputlist(list)
  if s:use_getchar
    echo join(a:list,"\n")
    echo "choose a number :"
    let answer = ''
    for i in range(1,len(string(len(a:list))))
      let c = getchar()
      if c == 13 
	break
      endif
      let answer .= nr2char(c)
    endfor
    let g:answer = answer
    if len(matchstr(answer, '\D')) > 0
      return 0
    else
      return answer
    endif
  else
    return inputlist(a:list)
  endif
endfunction

