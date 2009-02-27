"|func  adds another on thing handler to the current buffer
"|p     Example:
"|code  call tovl#ui#open_thing_at_cursor#AddOnThingHandler("[substitute(expand('<cWORD>'),'\\.','/','g').'\.lhs']")
function! tovl#ui#goto_thing_at_cursor#AddOnThingHandler(handler)
  let b = get(a:handler,'buffer',0)
  call tovl#list#AddUnique(
    \ config#Get{b ? 'B' : 'G'}('on_thing_handler', {'set' :1, 'default' : []}), a:handler)
endfunction

function! tovl#ui#goto_thing_at_cursor#RemoveOnThingHandler(handler)
  let b = get(a:handler,'buffer',0)
    call tovl#list#Remove(config#Get{b ? 'B' : 'G'}('on_thing_handler'), a:handler)
endfunction

function! s:DoesFileExist(value)
  if type(a:value) == 1
    let filename = a:value
  else
    let filename = a:value[0]
  endif
  return filereadable(expand(filename))
endif
endfunction

function! s:GotoLocation(value)
  if type(a:value) == 1
    if a:value == ""
      return 
    endif
    let filename = a:value
    let line_nr = -1
  else
    let filename = a:value[0]
    let line_nr = a:value[1]
  endif
  exec ":e ".filename
  if line_nr >= 0
    exec line_nr
  endif
endfunction

function! s:ParseItemStr(value)
  if a:value =~ ', line '
    let line = matchstr('\d*$',a:value)
    return [ substitute(a:value,', line .*','',''), line ]
  else
    return a:value
  endif
endfunction
  
function! s:ToItemStr(value)
  if type(a:value) == 1
    return a:value
  else
    return a:value[0].', line '.a:value[1]
  endif
endfunction

"|func  Use this function in your mapping in a ftplugin file like this:
"|code  noremap gf :call tovl#ui#open_thing_at_cursor#HandleOnThing()<cr>
function! tovl#ui#goto_thing_at_cursor#HandleOnThing()
  let pos = getpos('.')
  let possibleFiles = []
  for h in config#GetB('on_thing_handler', []) + config#GetG('on_thing_handler', {'set' :1, 'default' : []})
    call setpos('.',pos)
    call extend(possibleFiles, library#Call(h))
  endfor
  " always use default handler as well
  call extend(possibleFiles, s:DefaultHandler())
  let possibleFiles = tovl#list#Uniq(possibleFiles)

  " if one file exists use that
  let existingFiles = filter(deepcopy(possibleFiles), 's:DoesFileExist(v:val)')
  if len(existingFiles) == 1
    call s:GotoLocation(existingFiles[0])
  elseif len(existingFiles) > 1
    call s:GotoLocation(s:ParseItemStr(tovl#ui#choice#LetUserSelectIfThereIsAChoice(
      \ "which file do you want to edit?", 
      \ map(existingFiles, 's:ToItemStr(v:val)'))))
  elseif len(possibleFiles) == 1
     call s:GotoLocation(possibleFiles[0])
  elseif len(possibleFiles) > 1
     call s:GotoLocation(s:ParseItemStr(tovl#ui#choice#LetUserSelectIfThereIsAChoice(
      \ "which file do you want to edit?", 
      \ map(possibleFiles, 's:ToItemStr(v:val)'))))
  else
    echo "no file found"
  endif
endfunction 

function! s:GetFileFromList(list)
  if len(a:list) == 1
    return a:list[0]
  else
    let index=tovl#ui#choice#LetUserSelectIfThereIsAChoice(
      \ "Select the file to open/create", a:list,"returrn index")
    if index == 0
      return ""
    else
      return a:list[index-1]
    endif
  endif
endfunction

function! s:DefaultHandler()
  let s = expand('<cfile>')
  return s == "" ? [] : [s]
endfunction

function! tovl#ui#goto_thing_at_cursor#OnThingTagList(tag)
  let l = []
  for match in taglist(a:tag)
    if match(get(match,'cmd',''),'^\d\+$') >= 0
      " we are lucky, line numbers are given
      call add(l, [match['filename'], match['cmd']])
    else
      call add(l, match['filename'])
    endif
  endfor
  return l
endfunction
