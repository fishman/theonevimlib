" description:
" I often get traces like this within the log
"     function theonevimlibsetup#Setup..tovl#plugin_management#UpdatePlugins..library#Call..13..12..47, line 4
"
" But which damn function is 13, 12 and 47?
" This plugin tries to find and identify them as methods of plugins

" the implementation can be found in
function! plugins#tovl#debug_trace#PluginDebugTrace(p)
  let p = a:p
  let p['Tags'] = ['tovl','debugging','trace','throwpoint']
  let p['Info'] = "Tries to find numbered anonymous functions belonging to vim dict objects"

  let p['defaults']['tags'] = ['tovl_log']
  let p['feat_command'] = {
    \ 'identify_anonymous_funtions' : {
      \ 'name' : 'IdentifyNumberedFunctions',
      \ 'cmd' : 'call '.p.s.'.IdentifyNumberedFunctions(<q-args>)',
      \ 'attrs' : '-nargs=1',
      \ }
    \ }
  fun p.IdentifyNumberedFunctions(s)
    for l in plugins#tovl#debug_trace#FindPieces(a:s,{})| echo l | endfor
  endfun
  return p
endfunction

" objects: dict {"name", obj}. obj is searched for the numbered function as
" well
" ps: one of foo..23..bar or [ "foo", "23", "bar"] (this is what v:throwpoint
" contains
fun! plugins#tovl#debug_trace#FindPieces(ps, objects)
  let ps = type(a:ps) == 3 ? a:ps :  split(a:ps, '\.\.\| \|,')
  let lines = []
  for p in ps
    let list = plugins#tovl#debug_trace#FindPiece(p, a:objects)
    if len(list) > 0
      call add(lines, p.":(found: ".len(list)."):")
      for i in list[:2]
        call add(lines,  "   ".i)
      endfor
      if len(list) > 3
        cal add(lines,  "   some more")
      endif
    else
      cal add(lines,  p)
      cal add(lines,  " ")
    endif
  endfor
  return lines
endf

fun! plugins#tovl#debug_trace#FindPiece(p, objects)
  let locations = []
  if matchstr(a:p, '^\d\+$')
    " anonymous function, find it 
    let loaded = config#GetG('tovl#plugins#loaded')
    for pkey in keys(loaded)
      let plugin = loaded[pkey]
      for k in keys(plugin)
        if type(plugin[k]) == 2 && string(plugin[k]) == 'function('''.a:p.''')'
          call add(locations, "plugin ".pkey." and is method: ".k)
        endif
      endfor
    endfor
  endif

  for [k,o] in items(a:objects)
    for [km,M] in items(o)
      if type(M) == 2 && string(M) == 'function('''.a:p.''')'
	call add(locations, "obj ".k.",  method: ".km)
      endif
      unlet km M
    endfor
    unlet k o
  endfor
  return locations
endf
