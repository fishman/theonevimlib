function! plugins#tovl#config#PluginTOVL_Config(p)
  let p = a:p
  let p['Tags'] = ['tovl','configuration']
  let p['Info'] = "This is the plugin which can be used to configure some global "
        \ ." configuration settings. Also see core/doc/tovl.txt -> tovl-global-config"
  let p['loadingOrder'] = 10

  let p['defaults']['log_level'] = 0
  
  let child = {}
  fun! child.Load()
    if has_key(self.cfg, 'log_level')
      call tovl#log#GetLogger().SetLevel(self.cfg.log_level)
    endif
    call self.Parent_Load() 
  endfunction
  return p.createChildClass(child)
endfunction
