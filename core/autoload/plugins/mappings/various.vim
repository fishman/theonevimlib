function! plugins#mappings#various#PluginUsefulTabMappings(p)
  let p = a:p
  let p['Tags'] = ['feat_mapping','tabs','speed']
  let p['Info'] = "define some useful feat_mapping for faster navigation"
  let p['feat_mapping'] = { 'tab_new' : { 'tags' : ['tab_mappings'], 'lhs' : '<m-s-t>', 'rhs' : ':tabnew<cr>' }}
  let p['defaults']['mapping_goto_tab_nr_lhs'] = "<m-#nr#>"
  let p['defaults']['tags'] = ['tab_mappings']
  let child = {}

  fun! child.Load()
    let lhs = self.cfg.mapping_goto_tab_nr_lhs
    if lhs != ""
      for i in range(10,1,-1)
        call self.RegI({
              \ 'featType' : 'feat_mapping',
              \ 'lhs' : substitute(lhs,'#nr#', i,'g'),
              \ 'rhs': i.'gt'
              \ })
      endfor
    endif
    call self.Parent_Load()
  endfunction
  return p.createChildClass(child)
endfunction

function! plugins#mappings#various#PluginUsefulBufferMappings(p)
  let p = a:p
  let p['Tags'] = ['feat_mapping','buffer','speed']
  let p['Info'] = "define some useful feat_mapping for faster navigation"
  let p['defaults']['tags'] = ['useful_buffer_mappnigs']

  let p['feat_mapping'] = {
  \ 'inv_wrap' : {'lhs' : '<leader>wp', 'rhs' : ':set invwrap<cr>' },
  \ 'inv_list' : {'lhs' : '<leader>lt', 'rhs' : ':set invlist<cr>' },
  \ 'inv_hlsearch' : {'lhs' : '<leader>hl', 'rhs' : ':set invhlsearch<cr>' },
  \ 'normal_mode_write' : {'lhs' : '<m-s-r>', 'rhs' : '<esc>:w<cr>' },
  \ 'insert_mode_write' : {'m':'i', 'lhs' : '<m-s-r>', 'rhs' : '<esc>:w<cr>' },
  \ 'quit' : {'lhs' : '<m-s-q>', 'rhs' : ':q<cr>' },
  \ 'bdelete' : {'lhs' : '<m-s-b><m-s-d>', 
  \ 'rhs' : ':if<space>!&modified<bar><bar>input("not<space>saved,<space>really<space>bd!?<space>[y]")=="y"<bar>bd!<bar>endif<cr>' },
  \ 'edit' : {'lhs' : '<m-e>', 'rhs' : ':e<space>' },
  \ 
  \ 'open_custom_filetype' : {'lhs' : '<m-s-f><m-s-t><m-s-p>',
      \ 'rhs' : ":exec 'e '.config#DotVim().'/ftplugin/'.&filetype.'.vim'<cr>"},
  \
  \ 'fold_by_search_string' : {'lhs' : '<leader>fbss',
      \ 'rhs' : ':setlocal<space>foldexpr=getline(v:lnum)!~@/<bar>setlocal foldmethod=expr<CR><Bar>zM'},
  \ 'keep_lines' : {'lhs' : '<m-k><m-l>',
    \ 'rhs' : ":exec 'g!/'.input('filter expr :').'/d'<cr>"},
  \ 'drop_lines' : {'lhs' : '<m-d><m-l>',
    \ 'rhs' : ":exec 'g/'.input('filter expr :').'/d'<cr>"},
  \
  \ 'switch_buffer' : {'lhs' : '<m-a>', 'rhs' : ":b " },
  \ 'buffer_next' : {'lhs' : '<m-b><m-n>', 'rhs' : ":bnext<cr>" },
  \ 'buffer_previous' : {'lhs' : '<m-b><m-p>', 'rhs' : ":bprevious<cr>" },
  \ 
  \ 'reload_file_throw_away_changes' : {'lhs' : '<m-s-f>', 'rhs' : ":e! %<cr>" },
  \
  \ 'search_word_forward' : {'lhs' : '<m-w>/', 'rhs' : '/\<\><left><left>'},
  \ 'search_word_backward' : {'lhs' : '<m-w>?', 'rhs' : '?\<\><left><left>'},
  \
  \ 'cmd_insert_directory' : {'m':'c', 'lhs' : '>fn', 'rhs' : "<c-r>=expand('%:p')<cr>" },
  \ 'cmd_insert_filename' : {'m':'c', 'lhs' : '>fd', 'rhs' : "<c-r>=expand('%:p:h').'/'<cr>" },
  \ 
  \ 'set_buf_height_per_ten' : {'lhs' : '<m-w>', 'rhs' : ':call plugins#mappings#various#SetWindowSize("h")<cr>' },
  \ 'set_buf_width_per_ten' : {'lhs' : '<m-s-w>', 'rhs' : ':call plugins#mappings#various#SetWindowSize("w")<cr>' }
  \ }

  " useful for debugging TOVL.. should we use a proper logging system?
  let p['feat_mapping']['messages'] = {'lhs' : '<m-m><m-s>', 'rhs' : ":messages<cr>" }
  
  for i in ['h','j','k','l']
    let p['feat_mapping']['jump_window_'.i] = {
          \ 'lhs' : '<m-s-'.i.'>', 'rhs' : ':wincmd '.i.'<cr>'}
  endfor
  return p
endfunction

" set window height/width in 1/10th steps of total height/width
" parameter: 'h' or 'w' ( set height/width)
function! plugins#mappings#various#SetWindowSize(orientation)
    let fract = nr2char(getchar())
  if a:orientation == 'h'
    exec fract*&lines/10.'wincmd _'
  else
    exec fract*&columns/10.'wincmd |'
  endif
endfunction

fun! plugins#mappings#various#PluginUsefulQuickfixMappings(p)
  let a:p['defaults']['tags'] = ['useful_quickfix_mappings']
  let a:p['feat_mapping'] = {
      \ 'cprevious' : {'lhs' : '<m-.>', 'rhs' : ":cnext <cr>" },
      \ 'cnext' : {'lhs' : '<m-,>', 'rhs' : ":cprevious <cr>" },
      \
      \ 'keep_qf_items_by_file_regex' : {'lhs' : '<m-f><m-l>',
        \ 'rhs' : ":exec 'call tovl#quickfix#FilterQFListByRegex('.string(input('qf: filename keep re: ')).', {'drop' : 0, 'key' : 'filename'})'<cr>" },
      \ 'drop_qf_items_by_file_regex' : {'lhs' : '<m-r><m-l>',
        \ 'rhs' : ":exec 'call tovl#quickfix#FilterQFListByRegex('.string(input('qf: filename keep re: ')).', {'drop' : 1, 'key' : 'filename'})'<cr>" },
      \ }
  return a:p
endf

function! plugins#mappings#various#PluginUsefulVariousMappings(p)
  let p = a:p
  let p['Tags'] = ['feat_mapping','various','speed']
  let p['Info'] = "define some useful feat_mapping for faster navigation"
  let p['defaults']['tags'] = ['useful_various_mappings']
  let p['feat_mapping'] = {
    \ 'help' :{ 'lhs' : '<m-h>', 'rhs' : ':h ' },
    \ 'jum_end_of_line' : { 'm':'i', 'lhs' : '<c-e>', 'rhs' : '<esc>A' }
    \ }
  return p
endfunction
