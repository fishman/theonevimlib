" additional code belonging to the PluginSurround plugin
"
" probably this can be tidied up much.. (TODO)


" optional parameter in normal mode: normal characters to select text
" area to surround
" insert mode is broken
function! tovl#plugins#mappings#various_surround#SurroundText(left, right, map_mode)
  let g:left=a:left
  let g:right=a:right
  "if a:map_mode == 'i'
    "let norm_cmd =  "normal <esc>viw"
    "let g:d='i'
  "else
  if a:map_mode == 'n'
    if a:0>0
      let select_area=a:1
    else
      let select_area="iW"
    endif
    let norm_cmd = "v".select_area
    let g:d='n'
  elseif a:map_mode == 'v'
    let norm_cmd = 'gv'
    let g:d='v'
  endif
  " gv is necessary to get into visual mode again.. (is there a better way of
  " doing this?
  " s is used to remove the to be surrounded text and should be inserted again
  " with @- which doesn't work
  let a = @a
  exec 'normal '.norm_cmd.'"as'.a:left."\<c-r>a".a:right
  let @a = a
endfun

finish
" the following code has to be tested again

" reads characters  from user till one match of dict  is found
function! s:GetPairFromKeyboard()
  echo ' enter one of '.join(keys(g:pair_dict),', ')
  let max_len = 0 
  for k in keys(g:pair_dict)
    if len(k) > max_len
      let max_len = len(k)
    endif
  endfor
  let key = ""
  while len(key) < max_len
    let c = nr2char(getchar())
    let key .= c
    if exists("g:pair_dict[".string(key)."]")
      return g:pair_dict[key]
    endif
  endwhile
  throw "no known pair given!"
endfunction

function! tovl#plugins#mappings#various_surround#Surround(map_mode)
  let pair = s:GetPairFromKeyboard()
  call tovl#plugins#mappings#various_surround#SurroundText(pair[0],pair[1],a:map_mode)
endfunction

function! tovl#plugins#mappings#various_surround#SubstituteSurroundingText(subst, replace_with)
  " escape [
  let subst = s:PrepareForSearchpair(a:subst)
  if subst[0]!=subst[1]
    call searchpair(subst[0],'',subst[1],'')
    "start visual mode, mark pair
    exec "normal v?".subst[0]."\<cr>\<esc>"
  else
    " there is no start/ end so just use search keys
    let item = subst[0]
    exec "normal ?".item."<cr>v/".item."<cr>"
  endif
  let a = @a
  exec 'normal gv"as'.a:replace_with[0]."\<c-r>=matchstr(@a,'^'.".string(subst[0]).".'\\zs.*\\ze".subst[1]."$')\<cr>".a:replace_with[1]
  let @a=a
endfunction

function! tovl#plugins#mappings#various_surround#SubstituteSurrounding()
  let subst = s:GetPairFromKeyboard()
  let replace_with = s:GetPairFromKeyboard()
  call tovl#plugins#mappings#various_surround#SubstituteSurroundingText(subst, replace_with)
endfunction

function! s:PrepareForSearchpair(p)
  let subst = deepcopy(a:p)
  let subst = map(subst,"substitute(v:val,'[','\\\\[','')")
  return map(subst,"substitute(v:val,']','\\\\]','')")
endfunction

function! s:GetMostInnerSurrounding()
  let [l,c] = [-1,-1]
  let saved_pos = getpos('.')
  for key in keys(g:pair_dict)
    call setpos('.',saved_pos)
    let subst = s:PrepareForSearchpair(g:pair_dict[key])
    if searchpair(subst[0],'',subst[1],'b') > 0 
      let p = getpos('.')
      let [bufnum, lnum, coln, off] = p
      if lnum>=l && coln >= c 
            \ && vl#lib#buffer#utils#CompareCursorPos(p, saved_pos) >= 0
	let l = lnum
	let c = coln
	let k = key
      endif
    endif
  endfor
  if exists('k')
    return g:pair_dict[k]
  else
    throw "no inner most pair found"
  endif
endfunction

function! g:GMI()
  return s:GetMostInnerSurrounding()
endfunction

function! tovl#plugins#mappings#various_surround#SubstituteInnerMostSurrounding()
  let subst = s:GetMostInnerSurrounding()
  let replace_with = s:GetPairFromKeyboard()
  call tovl#plugins#mappings#various_surround#SubstituteSurroundingText(subst, replace_with)
endfunction

function! tovl#plugins#mappings#various_surround#RemoveSurrounding()
  let subst = s:GetPairFromKeyboard()
  let g:s = subst
  let replace_with = ["",""]
  call tovl#plugins#mappings#various_surround#SubstituteSurroundingText(subst, replace_with)
endfunction

function! tovl#plugins#mappings#various_surround#RemoveInnerMostSurrounding()
  let subst = s:GetMostInnerSurrounding()
  let replace_with = ["",""]
  call tovl#plugins#mappings#various_surround#SubstituteSurroundingText(subst, replace_with)
endfunction
