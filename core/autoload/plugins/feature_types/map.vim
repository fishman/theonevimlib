" userinterface of core/autoload/tovl/ui/open_thing_at_cursor.vim
function! plugins#feature_types#map#PluginMap(p)
  let p = a:p
  let p['Tags'] = []
  let p['Info'] = "This feature type adds the mappings. Maybe you prefer map_with_esc_hack over this"
  let p['loadingOrder'] = 50
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
    return substitute(substitute(a:s,'<m-\\(.\\)>','<esc>\\1','g'),'<m-s-\\(.\\)>','<esc><s-\\1>','g')
  endf
  return p
endfunction
