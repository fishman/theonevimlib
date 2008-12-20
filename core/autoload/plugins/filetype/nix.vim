" see also PluginSyntaxChecker
function! plugins#filetype#nix#PluginNixSupport(p)
  let p = a:p
  let p['Tags'] = ["nix"]
  let p['Info'] = "small nix features"
  let p['defaults']['tags'] = ['nix_support']
  let p['defaults']['tags_buftype'] = {'nix' : ['nix_support']}
  let p['feat_GotoThingAtCursor'] = {
      \ 'jump_to_path' : {
        \ 'f' : library#Function("return [ expand(expand('%:h').'/'.matchstr(expand('<cWORD>'),'[^;()[\\]]*')).'/default.nix'" .
          \ ", expand(expand('%:h').'/'.matchstr(expand('<cWORD>'),'[^;()[\\]]*'))" .
          \ ", expand('%:h').'/'.matchstr(getline('.'), 'import\\s*\\zs[^;) \\t]\\+\\ze')" .
          \ ", expand('%:h').'/'.matchstr(getline('.'), 'import\\s*\\zs[^;) \\t]\\+\\ze').'/default.nix' ]")
      \ }}
  " mappings to evaluate contents of current buffer using nix-instantiate
  let p['feat_mapping'] = {
      \ 'eval' : {
        \ 'lhs' : '<F2>',
        \ 'buffer' : 1,
        \ 'rhs' : ':call '.p.s.'.Run(0)<cr>' },
      \ 'eval_xml' : {
        \ 'buffer' : 1,
        \ 'lhs' : '<F3>',
        \ 'rhs' : ':call '.p.s.'.Run(1)<cr>' }}
  fun! p.Run(xml)
    update
    let cmd = tovl#runtaskinbackground#NewProcess({ 'name' : 'nix-instantiate',
          \ 'cmd' : ['nix-instantiate', '--eval-only'] + ( a:xml ? ["--xml"] : []) +  [library#Function('return expand("%")') ],
          \ 'ef' : 'plugins#tovl#errorformats#PluginErrorFormats#nix',
          \ 'onFinishCallbacks' : (a:xml ? ["cope"] : ["cope"])}
          \ )
    call cmd.Run()
  endf
  return p
endfunction
