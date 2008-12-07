function! plugins#buffer#utility#PluginCreateDirOnBufWrite(p)
  let p = a:p
  let p['Tags'] = ['buffer','demo']
  let p['Info'] = 'create directories before writing files'
  let p['defaults']['ask'] = 1

  let p['autocommands']['on_thing_handler'] = {
        \ 'events' : 'BufWritePre',
        \ 'pattern' : '*',
        \ 'cmd' : "call ".p.s.".CreateDir()" }

  function! p.CreateDir()
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

  return p
endfunction
