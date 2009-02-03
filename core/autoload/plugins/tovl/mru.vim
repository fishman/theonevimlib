" description:
" I often get traces like this within the log
"     function theonevimlibsetup#Setup..tovl#plugin_management#UpdatePlugins..library#Call..13..12..47, line 4
"
" But which damn function is 13, 12 and 47?
" This plugin tries to find and identify them as methods of plugins

" the implementation can be found in
function! plugins#tovl#mru#PluginMRU(p)
  let p = a:p
  let p['Tags'] = ['speed','most recent files','last edited']
  let p['Info'] = "remembers all files you've opened recently and shows them in a list so that you can open it"

  let p['events'] = ['BufNewFile','BufRead','BufWrite']
  for event in p['events']
    let p['defaults']['remember_on_'.event] = 1
  endfor
  let p['defaults']['count'] = 400

  let p['defaults']['tags'] = ['mru']
  let p['feat_command'] = {
    \ 'show_mru_list' : {
      \ 'name' : 'MRU',
      \ 'cmd' : 'call '.p.s.'.ShowMRUList()',
      \ 'attrs' : '-nargs=0',
      \ }
    \ }
  let p['feat_mapping'] = {
    \ 'show_mru_list' : {
      \ 'lhs' : '<m-s-o><m-s-r>',
      \ 'rhs' : ':call '.p.s.'.ShowMRUList()<cr>',
      \ }
    \ }
  fun p.ShowMRUList()
    let list = []
    let files = {}
    for i in config#GetC('/mru','mru_files', [])
      " only show a file once. the first match is sufficient
      if !has_key(files, i[1])
        call add(list, {'event' : i[0], 'file' : i[1]})
        let files[i[1]] = 1
      endif
    endfor
    call tovl#ui#filter_list#ListView({
          \ 'number' : 1,
          \ 'selectByIdOrFilter' : 1,
          \ 'Continuation' : library#Function('exec "e ".ARGS[0]["file"]'),
          \ 'items' : list,
          \ 'cmds' : ['wincmd J'],
          \ 'keys' : ['event', 'file'],
          \ 'aligned' : 1
          \ })
  endfun

  fun! p.Remember(event)
    if expand('%:p') == ''
      return
    endif
    " get current file conents 
    let c = config#GetC('/mru','mru_files', [])
    call add(c, [a:event, expand('%:p')])
    let c = c[0: self.cfg.count ]
    " force writing to disk:
    call config#SetC('/mru', 'mru_files', c)
  endf

  let child = {}
  fun! child.Load()
    let g:HighlightCurrentLine=0
    for event in self.events
      if get(self.cfg,'remember_on_'.event,0)
        call self.Au({'events': event, 'pattern': '*',
              \ 'cmd': 'silent! call '. self.s .'.Remember('.string(event).')'})
      endif
    endfor
    call self.Parent_Load()
  endf
  return p.createChildClass(child)
endfunction
