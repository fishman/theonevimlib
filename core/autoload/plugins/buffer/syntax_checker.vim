" author: Marc Weber
"
" TODO 
" 08:59 < spiiph> You might even want to use BufWriteCmd, if you want the write to 
"               fail if the syntax checker fails.

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
        \  'ef' : 'plugins#tovl#errorformats#PluginErrorFormats#ruby',
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

  " from http://vim.wikia.com/wiki/Python_-_check_syntax_and_run_script
  let ft['python'] = {
        \  'pattern' : '*.py',
        \  'run_in_background' : 0,
        \  'ef' : 'plugins#tovl#errorformats#PluginErrorFormats#python',
        \  'cmd' :['python','-c', library#Function("return 'import py_compile,sys; sys.stderr=sys.stdout; py_compile.compile(\"'.expand('%').'\")'")],
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
