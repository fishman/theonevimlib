function! plugins#mappings#various#PluginUsefulTabMappings(p)
  let p = a:p
  let p['Tags'] = ['mappings','tabs','speed']
  let p['Info'] = "define some useful mappings for faster navigation"
  let p['mappings']['tab_new'] = {'ft' : '', 'm':'n', 'lhs' : '<m-s-t>', 'rhs' : ':tabnew<cr>' }
  let p['defaults']['mappings']['goto_tab_nr'] = "<m-#nr#>"
  let child = {}

  fun! child.Load()
    let lhs = self.cfg.mappings.goto_tab_nr
    if lhs != ""
      for i in range(10,1,-1)
        call self.Map({'ft':'','m':'n','lhs':substitute(lhs,'#nr#', i,'g'),'rhs':i.'gt'})
      endfor
    endif
    call self.Parent_Load() 
  endfunction
  return p.createChildClass(child)
endfunction

function! plugins#mappings#various#PluginUsefulBufferMappings(p)
  let p = a:p
  let p['Tags'] = ['mappings','buffer','speed']
  let p['Info'] = "define some useful mappings for faster navigation"

  let p['mappings']['inv_wrap'] = {'ft' : '', 'm':'n', 'lhs' : '<leader>wp', 'rhs' : ':set invwrap<cr>' }
  let p['mappings']['inv_list'] = {'ft' : '', 'm':'n', 'lhs' : '<leader>lt', 'rhs' : ':set invlist<cr>' }
  let p['mappings']['inv_hlsearch'] = {'ft' : '', 'm':'n', 'lhs' : '<leader>hl', 'rhs' : ':set invhlsearch<cr>' }

  let p['mappings']['normal_mode_write'] = {'ft' : '', 'm':'n', 'lhs' : '<m-s-r>', 'rhs' : '<esc>:w<cr>' }
  let p['mappings']['insert_mode_write'] = {'ft' : '', 'm':'i', 'lhs' : '<m-s-r>', 'rhs' : '<esc>:w<cr>' }
  let p['mappings']['quit'] = {'ft' : '', 'm':'n', 'lhs' : '<m-s-q>', 'rhs' : ':q<cr>' }
  let p['mappings']['bdelete'] = {'ft' : '', 'm':'n', 'lhs' : '<m-s-b><m-s-d>',
        \ 'rhs' : ':if<space>!&modified<bar><bar>input("not<space>saved,<space>really<space>bd!?<space>[y]")=="y"<bar>bd!<bar>endif<cr>' }
  let p['mappings']['edit'] = {'ft' : '', 'm':'n', 'lhs' : '<m-e>', 'rhs' : ':e<space>' }

  let p['mappings']['open_custom_filetype'] = {'ft' : '', 'm':'n', 'lhs' : '<m-s-f><m-s-t><m-s-p>',
        \ 'rhs' : ":exec 'e '.config#DotVim().'/ftplugin/'.&filetype.'.vim'<cr>"}

  let p['mappings']['fold_by_search_string'] = {'ft' : '', 'm':'n', 'lhs' : '<leader>fbss',
        \ 'rhs' : ':setlocal<space>foldexpr=getline(v:lnum)!~@/<bar>setlocal foldmethod=expr<CR><Bar>zM'}

  let p['mappings']['switch_buffer'] = {'ft' : '', 'm':'n', 'lhs' : '<m-a>', 'rhs' : ":b " }
  let p['mappings']['buffer_next'] = {'ft' : '', 'm':'n', 'lhs' : '<m-b><m-n>', 'rhs' : ":bnext<cr>" }
  let p['mappings']['buffer_previous'] = {'ft' : '', 'm':'n', 'lhs' : '<m-b><m-p>', 'rhs' : ":bprevious<cr>" }

  let p['mappings']['reload_file_throw_away_changes'] = {'ft' : '', 'm':'n', 'lhs' : '<m-s-f>', 'rhs' : ":e! %<cr>" }

  let p['mappings']['cmd_insert_directory'] = {'ft' : '', 'm':'c', 'lhs' : '>fn', 'rhs' : "<c-r>=expand('%:p')<cr>" }
  let p['mappings']['cmd_insert_filename'] = {'ft' : '', 'm':'c', 'lhs' : '>fd', 'rhs' : "<c-r>=expand('%:p:h').'/'<cr>" }

  " useful for debugging TOVL.. should we use a proper logging system?
  let p['mappings']['messages'] = {'ft' : '', 'm':'n', 'lhs' : '<m-m><m-s>', 'rhs' : ":messages<cr>" }
  
  for i in ['h','j','k','l']
    let p['mappings']['jump_window_'.i] = {'ft' : '', 'm':'n', 
          \ 'lhs' : '<m-s-'.i.'>', 'rhs' : ':wincmd '.i.'<cr>'}
  endfor
  return p
endfunction

fun! plugins#mappings#various#PluginUsefulQuickfixMappings(p)
  let a:p['mappings']['cprevious'] = {'ft' : '', 'm':'n', 'lhs' : '<m-.>', 'rhs' : ":cnext <cr>" }
  let a:p['mappings']['cnext'] = {'ft' : '', 'm':'n', 'lhs' : '<m-,>', 'rhs' : ":cprevious <cr>" }

  let a:p['mappings']['keep_qf_items_by_file_regex'] = {'ft' : 'quickfix', 'm':'n', 'lhs' : '<m-f><m-l>',
        \ 'rhs' : ":exec 'call tovl#quickfix#FilterQFListByRegex('.string(input('qf: filename keep re: ')).', {'drop' : 0, 'key' : 'filename'})'<cr>" }
  let a:p['mappings']['drop_qf_items_by_file_regex'] = {'ft' : 'quickfix', 'm':'n', 'lhs' : '<m-r><m-l>',
        \ 'rhs' : ":exec 'call tovl#quickfix#FilterQFListByRegex('.string(input('qf: filename keep re: ')).', {'drop' : 1, 'key' : 'filename'})'<cr>" }

  let a:p['mappings']['cnext'] = {'ft' : 'quickfix', 'm':'n', 'lhs' : '<m-,>', 'rhs' : ":cprevious <cr>" }

  let child={}

  fun! child.Load()
    "call self.Au({'events' : 'QuickFixCmdPost', 'pattern' : '*',
    "      \ 'cmd' : 'echoe "war"' ]})
    call self.Parent_Load()
  endf

  return a:p.createChildClass(child)
endf


function! plugins#mappings#various#PluginUsefulVariousMappings(p)
  let p = a:p
  let p['Tags'] = ['mappings','various','speed']
  let p['Info'] = "define some useful mappings for faster navigation"

  let p['mappings']['help'] =
    \ { 'ft' : '', 'm':'n', 'lhs' : '<m-h>', 'rhs' : ':h ' }
  let p['mappings']['jum_end_of_line'] = 
    \ { 'ft' : '', 'm':'i', 'lhs' : '<c-e>', 'rhs' : '<esc>A' }
  return p
endfunction
