" description:
" I often get traces like this within the log
"     function theonevimlibsetup#Setup..tovl#plugin_management#UpdatePlugins..library#Call..13..12..47, line 4
"
" But which damn function is 13, 12 and 47?
" This plugin tries to find and identifyt them as methods of plugins

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
    call plugins#tovl#debug_trace#FindAndPrintPieces(split(a:s, '\.\.\| \|,'))
  endfun
  return p
endfunction

fun! plugins#tovl#debug_trace#FindAndPrintPieces(ps)
  for p in a:ps
    let list = plugins#tovl#debug_trace#FindPiece(p)
    if len(list) > 0
      echo p.":(found: ".len(list)."):"
      for i in list[:2]
        echo "   ".i
      endfor
      if len(list) > 3
        echo "   some more"
      endif
    else
      echo p
      echo " "
    endif
  endfor
endf

fun! plugins#tovl#debug_trace#FindPiece(p)
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
  return locations
endf
