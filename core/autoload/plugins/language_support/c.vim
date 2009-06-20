" some minimal C language support
" gf to jump to header locations.
"
" use call add(config#GetG('config#header_locations', {'default' : [], 'set' : 1}), "your additional header location")
" to add project specific locations.. for now

function! plugins#language_support#c#PluginC(p)
  let p = a:p
  let p['Tags'] = ["nix"]
  let p['Info'] = "jump to header locations"
  let p['defaults']['tags'] = ['c']
  let p['defaults']['tags_buftype'] = {'c' : ['c'], 'cpp' : ['cpp']}
  let p['defaults']['header_locations'] = [['/usr/include']]
  fun! p.HeaderFromLine()
    return matchstr(getline('.'), '#\s*include\s\+"\zs[^"]*\ze"\|#\s*include <\zs[^>]*\ze>')
  endf
  fun! p.HeaderLocations()
    let header = self.HeaderFromLine()
    if header == ""
      return []
    else
      return map(tovl#list#Concat(
                \ map(copy(self.cfg.header_locations + config#GetG('config#header_locations', [])), 'library#Call(v:val)')),
            \ 'v:val."/".'.string(header))
    endif
  endf


  let p['feat_GotoThingAtCursor'] = {
      \ 'jump_to_path' : {
        \ 'buffer' : 1
        \ ,'f' : library#Function('return '. p.s .'.HeaderLocations()')
      \ }}
  return p
endfunction
