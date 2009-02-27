function! plugins#vcs#git#PluginGit(p)
  let p = a:p
  let p['Tags'] = []
  let p['Info'] = "uses PluginExecUrl to show git hash comits"

  let p['defaults']['tags'] = ['git']

  let p['feat_GotoThingAtCursor'] = {
      \ 'show_git_commit_by_hash' : {
        \ 'buffer' : 0
        \ ,'f' : library#Function("return ". p.s .".GitShowCommit()")}}

  let p['feat_command'] = {
    \ 'git_blame' : {
      \ 'name' : 'GitBlame',
      \ 'attrs' : '-nargs=0',
      \ 'cmd' : 'exec "e tovl_exec://git?blame?".expand("%")' },
    \ 'git_diff' : {
      \ 'name' : 'GitDiff',
      \ 'attrs' : '-nargs=0',
      \ 'cmd' : 'call '. p.s .'.GitDiff(<f-args>)' }
    \ }

  fun! p.GitDiff()
    let proposal = "show HEAD:".expand('%')
    let args = join(map(split(input("git : ", proposal),'\s\+'),'"?".v:val'),'')
    diffthis
    exec 'vsplit tovl_exec://git'.args
    diffthis
    " TODO: if you close the diff window call diffoff 
  endf

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
