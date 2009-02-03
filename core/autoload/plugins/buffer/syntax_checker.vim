" author: Marc Weber
"
" use call
" vl#lib#hl#vim7highlightCurrentLineInActiveWindow#ToggleHighlightCurrentLine() to toggle highlighting of the cursor
" only in active window

" example mapping:
  " noremap <m-h><m-c> :call vl#lib#hl#vim7highlightCurrentLineInActiveWindow#ToggleHighlightCurrentLine()<cr>

" TODO refactor its best to put this all into small items within the filetype
" directory? Then you can only enable those pieces you want

function! plugins#buffer#syntax_checker#PluginSyntaxChecker(p)
  let p = a:p
  let p['Tags'] = ['syntax','php','javascript','xml']
  let p['Info'] = "This plugins runs a syntax checker after writing the file"

  " put cursor on autolad function and press gf to jump to the file or to create
  " a new file.
  let p['defaults']['filetypes'] = {}
  let ft = p['defaults']['filetypes']
  let ft['nix'] = {
        \  'pattern' : '*.nix',
        \  'run_in_background' : 0,
        \  'ef' : 'plugins#tovl#errorformats#PluginErrorFormats#nix',
        \  'cmd' : ['nix-instantiate','--parse-only', library#Function("return expand('%')")],
        \  'active' : 1
        \ }
  " spidermonkey doesn't catch {"a" : 2,}. IE fails with that
  let ft['js'] = {
        \  'pattern' : '*.js',
        \  'run_in_background' : 0,
        \  'ef' : 'plugins#tovl#errorformats#PluginErrorFormats#js_spidermonkey',
        \  'cmd' :['js', '-C', library#Function("return expand('%')")],
        \  'active' : 1
        \ }
  let ft['xml'] = {
        \  'pattern' : '*.xml',
        \  'run_in_background' : 0,
        \  'ef' : 'plugins#tovl#errorformats#PluginErrorFormats#xmllint',
        \  'cmd' :['xmllint' ,'--valid','--loaddtd', '--noout', '--load-trace', library#Function("return expand('%')")],
        \  'active' : 1
        \ }
  let ft['rb'] = {
        \  'pattern' : '*.rb',
        \  'run_in_background' : 0,
        \  'ef' : 'plugins#tovl#errorformats#PluginErrorFormats#php',
        \  'cmd' :['ruby','-c', library#Function("return expand('%')")],
        \  'active' : 1
        \ }
  let ft['php'] = {
        \  'pattern' : '*.php',
        \  'run_in_background' : 0,
        \  'ef' : 'plugins#tovl#errorformats#PluginErrorFormats#php',
        \  'cmd' :['php','-l', library#Function("return expand('%')")],
        \  'active' : 1
        \ }
  let ft['perl'] = {
        \  'pattern' : '*.pl',
        \  'run_in_background' : 0,
        \  'ef' : 'plugins#tovl#errorformats#PluginErrorFormats#perl',
        \  'cmd' :['perl','-c', library#Function("return expand('%')")],
        \  'active' : 1
        \ }

  let child = {}
  fun! child.Load()
    let g:HighlightCurrentLine=0
    for k in keys(self.cfg.filetypes)
      if !get(self.cfg.filetypes[k],'active',0)
        continue
      endif
      let v = self.cfg.filetypes[k]
      try
        call self.Au({'events': 'bufwritepost', 'pattern': v.pattern,
              \ 'cmd': "silent! call tovl#runtaskinbackground#NewProcess( "
              \         ."{ 'name' : 'syntax_checker_plugin', 'cmd': ".string(v.cmd).", 'ef' : ".string(v.ef).", 'fg' : ".(!get(v,'background',0)).", 'expectedExitCode' : '*' }).Run()"})
      catch /.*/
        call self.Log(0, 'exception while setting up syntax check for '.k)
      endtry
    endfor
    call self.Parent_Load()
  endf
  return p.createChildClass(child)
endfunction
