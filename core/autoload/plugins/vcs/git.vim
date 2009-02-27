function! plugins#vcs#git#PluginGitGotoHash(p)
  let p = a:p
  let p['Tags'] = []
  let p['Info'] = "uses PluginExecUrl to show git hash comits"

  let p['defaults']['tags'] = ['git']

  let p['feat_GotoThingAtCursor'] = {
      \ 'show_git_commit_by_hash' : {
        \ 'buffer' : 0
        \ ,'f' : library#Function("return ". p.s .".GitShowCommit()")}}

  fun! p.GitShowCommit()
    " only add commit location if the commit exists
    try
      let hash = substitute(expand('<cword>'),'[<>]','','g')
      call tovl#runtaskinbackground#System(["git","rev-list","-1",hash])
      " no failure 
      let list = [ 'tovl_exec://git?show?'.hash ]
    catch /.*/
      let list = []
    endtry
    return list
  endf
  return p
endfunction
