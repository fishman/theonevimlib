function! plugins#tovl#config#PluginTOVL_Config(p)
  let p = a:p
  let p['Tags'] = ['tovl','configuration']
  let p['Info'] = "This is the plugin which can be used to configure some global "
        \ ." configuration settings. Also see core/doc/tovl.txt -> tovl-global-config"
  let p['loadingOrder'] = 10

  let p['defaults']['log_level'] = 0
  " these options may be cached.. So you'll have to restart vim to make
  " changes take effect.. eg do this by
  " let s:cache_dir = library#Call(config#Get('plugins#tovl#config#PluginTOVL_Config#cache_dir'))
  let p['defaults']['cache_dir'] = library#Function('return expand("$HOME")."/.tovl-cache"')
  
  let child = {}
  fun! child.Load()
    if has_key(self.cfg, 'log_level')
      let l = tovl#log#GetLogger().SetLevel(self.cfg.log_level)
    endif
    let d = library#Call(self.cfg.cache_dir)
    if !isdirectory(d)
      let msg = "creating cachedir ".d
      call self.Log(1, msg) | echom "tovl: ".msg
      call mkdir(d,'p',0700)
    endif
    call self.Parent_Load() 
  endfunction
  return p.createChildClass(child)
endfunction
