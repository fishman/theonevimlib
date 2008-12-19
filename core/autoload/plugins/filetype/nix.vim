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
  return p
endfunction
