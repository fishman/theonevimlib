" userinterface of tovl/ui/multiple_completions.vim
function! plugins#filetype#quickfix#quickfix#PluginQuickfix(p)
  let p = a:p
  let p['Tags'] = ['quickfix']
  let p['Info'] = "some usefule mappings for the quickfix window"

  let p['defaults']['tags'] = ['quickfix']
  let p['defaults']['tags_buftype'] = {'quickfix' : ['quickfix']}

  " make sure this is loaded after various.vim because both define mappings
  " with <m-k><m-l>
  let p['loadingOrder'] = 200


  let p['feat_mapping'] = {
      \ 'cprevious' : {'lhs' : '<m-.>', 'rhs' : ":cnext <cr>" },
      \ 'cnext' : {'lhs' : '<m-,>', 'rhs' : ":cprevious <cr>" },
      \
      \ 'keep_qf_items_by_file_regex' : {
        \ 'lhs' : '<m-k><m-l>',
	\ 'buffer' : 1,
        \ 'rhs' : ":call ". p.s .".Filter('v:val[\"filename\"] =~ '.string(input('qf: filename keep re: ')))<cr>"
        \ },
      \ 'drop_qf_items_by_file_regex' : {
        \ 'lhs' : '<m-d><m-l>',
	\ 'buffer' : 1,
        \ 'rhs' : ":call ". p.s .".Filter('v:val[\"filename\"] !~ '.string(input('qf: filename keep re: ')))<cr>"
      \ },
      \ 'keep_qf_items_by_text_regex' : {
        \ 'lhs' : '<m-k><m-t>',
	\ 'buffer' : 1,
        \ 'rhs' : ":call ". p.s .".Filter('v:val[\"text\"] =~ '.string(input('qf: filename keep re: ')))<cr>"
      \ },
      \ 'drop_qf_items_by_text_regex' : {
        \ 'lhs' : '<m-d><m-t>',
	\ 'buffer' : 1,
        \ 'rhs' : ":call ". p.s .".Filter('v:val[\"text\"] !~ '.string(input('qf: filename keep re: ')))<cr>"
      \ }
    \ }
  fun! p.Filter(filter)
    let list = getqflist()
    for l in list
      let l['filename'] = bufname(l['bufnr'])
    endfor
    call filter(list, a:filter)
    call setqflist(list,'r') " is this what you want?
  endf
  return p
endfunction
