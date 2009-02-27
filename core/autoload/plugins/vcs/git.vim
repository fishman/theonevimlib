function! plugins#vcs#git#PluginGit(p)
  let p = a:p
  let p['Tags'] = []
  let p['Info'] = "uses PluginExecUrl to show git hash comits"

  let p['defaults']['tags'] = ['git']

  let p['feat_GotoThingAtCursor'] = {
      \ 'show_git_commit_by_hash' : {
        \ 'buffer' : 0
        \ ,'f' : library#Function("return ". p.s .".GitShowCommit()")}}

  " all buffer related commands start by 'B' when it does make sense to run
  " the command for whole rep or a the current buffer
  " putting Git last so that you'll have to type less (tab completion)
  let p['feat_command'] = {
    \ 'git_blame' : {
      \ 'name' : 'BBlameGit',
      \ 'attrs' : '-nargs=0',
      \ 'cmd' : 'exec "e tovl_exec://git?blame?".expand("%")' },
    \ 'git_diff_current_buffer' : {
      \ 'name' : 'DiffCurrentBufferGit',
      \ 'attrs' : '-nargs=0',
      \ 'cmd' : 'call '. p.s .'.GitCurrentBuffer(<f-args>)' },
    \ 'git_diff_cached' : {
      \ 'name' : 'DiffCachedGit',
      \ 'attrs' : '-nargs=0',
      \ 'cmd' : 'e tovl_exec://git?diff?--cached' },
    \ 'buffer_git_diff_cached' : {
      \ 'name' : 'BDiffCachedGit',
      \ 'attrs' : '-nargs=0',
      \ 'cmd' : 'update|exec "e tovl_exec://git?diff?--cached?".expand("%")'},
    \ 'buffer_git_add' : {
      \ 'name' : 'BAddGit',
      \ 'attrs' : '-nargs=0',
      \ 'cmd' : 'update|!git add %'},
    \ 'buffer_git_add_patch' : {
      \ 'name' : 'BAddPatchGit',
      \ 'attrs' : '-nargs=0',
      \ 'cmd' : 'update|!git add --patch %'},
    \ 'git_init' : {
      \ 'name' : 'GitInit',
      \ 'attrs' : '-nargs=0',
      \ 'cmd' : '!git init'},
    \ 'git_log' : {
      \ 'name' : 'LogGit',
      \ 'attrs' : '-nargs=*',
      \ 'cmd' : 'call '. p.s .'.GitLog(<f-args>)'},
    \ 'buffer_git_commit' : {
      \ 'name' : 'BCommitGit',
      \ 'attrs' : '-nargs=0',
      \ 'cmd' : 'update| call '. p.s .'.BCommit()'},
    \ 'git_commit' : {
      \ 'name' : 'CommitGit',
      \ 'attrs' : '-nargs=0',
      \ 'cmd' : 'cal '. p.s .'.Commit()'}
    \ }
  fun! p.BCommit()
    " ensure nothing else is staged
    try
      if !empty(tovl#runtaskinbackground#System(['git','diff','--cached']))
        let r = input("You already have cached some lines, proceed? [y = yes, r = run git reset first,* = abort]") 
        if r == "r"
          !git reset
        elseif r != "y"
          echo "user abort" | return
        endif
      endif
    catch /.*/
      if v:exception =~ 'No HEAD commit to compare with'
        call self.Log(1,"can't check for staged changes, no HEAD yet")
      else
        throw v:exception
      endif
    endtry
    !git add %
    call self.Commit()
  endf

  fun! p.Sep(name)
    return "#===== ".a:name." ====================================================="
  endf

  fun! p.Clean()
    try
      call tovl#runtaskinbackground#System(["git","status"])
      " exit status 0 = there are changes
      return 0
    catch /.*/
      return 1
    endtry
  endf

  fun! p.Commit()
    if self.Clean()
      echo "nohting to commit" | return
    endif
    call tovl#scratch_buffer#ScratchBuffer({
      \ 'name' : "comitting to git repository"
      \ ,'onWrite' : library#Function(self.CommitOnBufWrite, {'self' : self})
      \ ,'help' : ["commit current staged changes to git. It's always save to just bd!"]
      \ ,'getContent' : library#Function('return ["", '. self.s .'.Sep("GIT COMMIT"), "Put your commit message above this separator, you see git status output below" ]'
                                       \ .'+ split(tovl#runtaskinbackground#System(["git","status"]),'.string("\n").')')
      \ ,'cmds' : ['set filetype=gitcommit','normal gg','startinsert']
      \ })
  endf

  fun! p.CommitOnBufWrite()
    let lines = getline(1,line('$'))
    " remove separator and git status output:
    let sep = self.Sep("GIT COMMIT")
    let i = 0
    while i < len(lines)
      if lines[i] == sep
        let lines = lines[0:(i-1)]
        break
      endif
      let i = i+1
    endwhile
    if empty(substitute(join(lines),'\s','','g'))
      echo "user abort, empty commit message"
      return
    endif
    call tovl#runtaskinbackground#System(['git','commit','-F','-'], {'stdin-text' : join(lines, "\n")})
    bw!
  endf

  fun! p.GitLog()
    if a:0 == 0
      " only show about 200 commits"
      let proposal = "log -200"
    else
      let proposal = "log ".join(a:000,' ')
    endif
    let args = join(map(split(input("git : ", proposal),'\s\+'),'"?".v:val'),'')
    exec 'vsplit tovl_exec://git'.args
  endf

  fun! p.GitDiffCurrentBuffer()
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
