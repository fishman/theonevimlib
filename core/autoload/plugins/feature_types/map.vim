" userinterface of core/autoload/tovl/ui/open_thing_at_cursor.vim
function! plugins#feature_types#map#PluginMap(p)
  let p = a:p
  let p['Tags'] = []
  let p['Info'] = "This feature type adds the mappings. Maybe you prefer map_with_esc_hack over this"
  let p['loadingOrder'] = 45
  fun! p.AddMapping(i)
    call self.LogExec(2, '+mapping ', get(a:i,'m','').'noremap '.(get(a:i, 'buffer', 0) ? '<buffer>' : '').' '
          \ .a:i['lhs'].' '
          \ .a:i['rhs'])
  endf
  fun! p.Subst(s)
    return a:s
  endf
  fun! p.AddMapping(i)
    call self.LogExec(2, '+mapping ', get(a:i,'m','').'noremap '.(get(a:i, 'buffer', 0) ? '<buffer>' : '').' '
          \ . self.Subst(a:i['lhs']).' '
          \ .a:i['rhs'])
  endf
  fun! p.DelMapping(i)
    call self.LogExec(2, '-mapping', get(a:i,'m','').'unmap '.(get(a:i, 'buffer',0) ? '<buffer>' : '').' '
          \ . self.Subst(a:i['lhs']))
  endf
  let p['defaults']['configDummy'] = "make this plugin load cause it hasn't any options"
  let p['featureTypes'] = {
        \ 'feat_mapping' : {
        \ 'AddItem' : library#Function(p.AddMapping, {'self' : p}),
        \ 'DelItem' : library#Function(p.DelMapping, {'self' : p}),
        \ }}
  return p
endfunction

" userinterface of core/autoload/tovl/ui/open_thing_at_cursor.vim
function! plugins#feature_types#map#PluginMapEscHack(p)
  let p = plugins#feature_types#map#PluginMap(a:p)
  let p['Info'] = "This feature type adds the mappings. Prefer this plugin"
        \ . " over PluginMap if you want to use <m-*> mappings when running console vim."
  " only this function differs from PluginMap
  fun! p.Subst(s)
    return plugins#feature_types#map#Subst(a:s)
  endf
  let child = {}
  fun! child.Load()
    " this loop defines the Nnoremap Noremap Inoremap Vnoreamp commands as
    " replacement for the default commands. This commands will do the <m-a> to
    " <esc>a conversion for you as well
    for c in [["Nn","nn"],["In","in"],["Vn","vn"],["N","n"]]
      exec "command! -nargs=* ".c[0]."oremap exec '".c[1]."oremap 'plugins#feature_types#map#SubstMapPart(<q-args>)"
    endfor
    call self.Parent_Load()
  endf

  return p.createChildClass(child)
endfunction

fun! plugins#feature_types#map#SubstMapPart(s)
  let lhsrhs = matchlist(a:s,'^\(\%(<buffer>\s\+\)\=\)\(\S*\)\s\+\(.*\)')
  echom lhsrhs[1].' '.plugins#feature_types#map#Subst(lhsrhs[2]).' '.lhsrhs[3]
  return lhsrhs[1].' '.plugins#feature_types#map#Subst(lhsrhs[2]).' '.lhsrhs[3]
endf

function! plugins#feature_types#map#Subst(s)
  if has('gui_running')
    return a:s
  else
    " <s-F10>
    let r = substitute(a:s,'<s-\cf\(\d\+\)>','\="<esc>[".(submatch(1)+22)."~"','g')
    " <c-F10>
    let r = substitute(r,'<c-\cf\(\d\+\)>','\="<esc>[".(submatch(1)+10)."^"','g')
    " <m-x> and <m-s-x>
    let r = substitute(substitute(r,'<m-\(.\)>','<esc>\1','g'),'<m-s-\(.\)>','<esc><s-\1>','g')
    return r
  endif
endf
