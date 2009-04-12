function! plugins#misc#rfc#PluginRFC(p)
  let p = a:p
  let p['Tags'] = ['rfc']
  let p['Info'] = "Download and cache rfc files"
  " TODO : refactor tovl-cache !
  let p['defaults']['tags'] = ['rfc']
  let p['defaults']['rfc_store_dir'] = library#Function('return expand("$HOME")."/.tovl-cache/rfc"')
  let p['defaults']['rfc_url_template'] = 'http://www.ietf.org/rfc/rfc${NR}.txt'

  let p['feat_command'] = {
    \ 'show_or_get_rfc' : {
      \ 'name' : 'RFC',
      \ 'cmd' : 'call '.p.s.'.OpenRFC(<f-args>)',
      \ 'attrs' : '-nargs=1',
      \ 'complete' : 'plugins#misc#rfc#CompleteRFCFiles',
      \ }
    \ }


  " command! -bang -range=% -nargs=1 -complete=customlist,vl#docs#rfc#CompleteRFCFiles RFC :call vl#docs#rfc#OpenRFC(<f-args>,"txt")

  fun p.OpenRFC(number)
    let dir = library#Call(self.cfg.rfc_store_dir )
    if !isdirectory(dir) | call mkdir(dir, 'p') | endif
    let file_on_disk=dir.'/RFC'.a:number.'.txt'

    if !filereadable(file_on_disk)
      " download it
      let url = substitute(self.cfg.rfc_url_template,'${NR}',a:number,'g')
      call tovl#runtaskinbackground#System(['wget','-O',file_on_disk,url])
    endif
    if !filereadable(file_on_disk)
      echoe "couldn't neither find nor download ".file_on_disk
      return
    endif
    " open for reading
    let buf_nr=bufnr('.')
    exec "e ".file_on_disk
    if expand('%:p') == file_on_disk
      set readonly
      set ft=rfc
    endif
  endfun

  fun! p.CompleteRFCFiles(A,L,P)
    # FIXME this function
    let fl = split(glob(s:rfc_save_dir.'/*'),"\n")
    let l2 = filter(map(fl,"matchstr(v:val,'\\d\\+')"),"v:val=~'^".a:A."'")
    return l2
  endf

  return p
endfunction

function! plugins#misc#rfc#CompleteRFCFiles(A,L,P)
  " wrapper calling function above
  let d = tovl#plugin_management#Plugin('plugins#misc#rfc#PluginRFC')
  return call(d.CompleteRFCFiles, a:000, d)
endfunction
