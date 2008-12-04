let s:file = expand('<sfile>')

function! plugins#buffer#utility#PluginCreateDirOnBufWrite()
  let d = {
        \ 'Tags': ['buffer','demo'],
        \ 'Info': 'create directories before writing files',
        \ }

  function! d.Load()
    " can't use self here :-(
    exec "autocmd BufWritePre * call tofl#plugin_management#Plugin(".string(self['pluginName']).").CreateDir()"
  endfunction

  function! d.CreateDir()
    let dir = expand('%:h')
    let cfg = config#Get(self.pluginName, {'default' : {}})
    if !isdirectory(dir) && dir != ""
      if (get(cfg, 'ask', 1))
        echo "create dir ".dir." ? [y/n]"
        if getchar() != char2nr('y')
          return 
        endif
      endif  
      call mkdir(dir, 'p')
     endif
  endfunction

  let d['defaults'] = { 'ask' : 1 }
  return d
endfunction
