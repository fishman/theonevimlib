function! plugins#vcs#git#PluginGit(p)
  let p = a:p
  let p['Tags'] = []
  let p['Info'] = "uses PluginExecUrl to show git hash comits"

  let p['defaults']['tags'] = ['git']

  let p['defaults']['tags_buftype'] = {'git_status_view' : ['git_status_view']}

  let p['feat_GotoThingAtCursor'] = {
      \ 'show_git_commit_by_hash' : {
        \ 'buffer' : 0
        \ ,'f' : library#Function("return ". p.s .".GitGotoLocations()")}}

  " all buffer related commands start by 'B' when it does make sense to run
  " the command for whole rep or a the current buffer
  " putting Git last so that you'll have to type less (tab completion)
  " BAddGitPatch Git is not last so that you'll get the first using tab
  " completion
  let p['feat_command'] = {
    \ 'git_blame' : {
      \ 'name' : 'BBlameGit',
      \ 'attrs' : '-nargs=0',
      \ 'cmd' : 'exec "e tovl_exec://git?blame?".expand("%")' },
    \ 'git_diff' : {
      \ 'name' : 'DiffGit',
      \ 'attrs' : '-nargs=0',
      \ 'cmd' : 'e tovl_exec://git?diff?' },
    \ 'git_checkout_buffer' : {
      \ 'name' : 'BCheckoutGit',
      \ 'attrs' : '-nargs=*',
      \ 'cmd' : 'call '. p.s .'.BCheckout(<f-args>)' },
    \ 'buffer_diff_current_buffer' : {
      \ 'name' : 'BDiff',
      \ 'attrs' : '-nargs=0',
      \ 'cmd' : 'update|exec "e tovl_exec://git?diff?".expand("%")'},
    \ 'git_diff_current_buffer_split' : {
      \ 'name' : 'BDiffSplitGit',
      \ 'attrs' : '-nargs=0',
      \ 'cmd' : 'call '. p.s .'.BDiffGitSplit(<f-args>)' },
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
      \ 'name' : 'BAddGitPatch',
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
      \ 'cmd' : 'call '. p.s .'.Commit()'},
    \ 'git_status_with_actions' : {
      \ 'name' : 'StatusGit',
      \ 'attrs' : '-nargs=0',
      \ 'cmd' : 'call '. p.s .'.StatusAndActions()'}
    \ }

  let p['feat_mapping'] = {}
  let names = {'a' : 'add', 'p' : 'add_patch', 'u' : 'unstage', 'r' : 'rm', 'd' : 'diff', 'D': 'diff_split', 'c' : 'commit' }
  for i in keys(names)
    let p['feat_mapping']['git_status_view_'.names[i]] = {
        \ 'lhs' : i,
        \ 'buffer' : 1,
        \ 'rhs' : ':call '.p.s.'.StatusViewAction('.string(i).')<cr>',
        \ 'tags' : ['git_status_view'] }
  endfor

  fun! p.BCheckout()
    exec '!git checkout '.expand('%')." ".join(a:000," ")
    " reload contents:
    e!
  endf
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
      \ ,'getContent' : library#Function('return ["", '. self.s .'.Sep("GIT COMMIT"), "Put your commit message above this separator","","==== git status ==="]'
                                       \ .'+ split(tovl#runtaskinbackground#System(["git","status"]),'.string("\n").')'
                                       \ .'+ ["","==== git diff --cached ==="]'
                                       \ .'+ split(tovl#runtaskinbackground#System(["git","diff","--cached"]),'.string("\n").')')
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

  fun! p.BDiffGit()
    let proposal = "show HEAD:".expand('%')
    let args = join(map(split(input("git : ", proposal),'\s\+'),'"?".v:val'),'')
    diffthis
    exec 'vsplit tovl_exec://git'.args
    diffthis
    " TODO: if you close the diff window call diffoff 
  endf

  fun! p.GitGotoLocations()
    " only add commit location if the commit exists
    let thing = expand('<cWORD>')
    echom thing
    if thing =~ '^[ab]/'
      " diff file a/foo/bar ? strip a
      if filereadable(thing[2:])
        return [thing[2:]]
      endif
      return []
    else
      " hash ?
      try
        let hash = substitute(thing,'[<>]','','g')
        call tovl#runtaskinbackground#System(["git","rev-list","-1",hash])
        " no failure 
        let list = [ 'tovl_exec://git?show?'.hash ]
      catch /.*/
        let list = []
      endtry
      return list
    endif
  endf

  fun! p.StatusAndActions()
    let help = [
      \ '===  file actions ==='
      \ ,'p = add patched'
      \ ,'a = stage (git add)'
      \ ,'u = unstage (git rm --cached)'
      \ ,'r = rm (git rm)'
      \ ,'d = !git diff on file'
      \ ,'c = :CommitGit'
      \ ]
    " call search to place the cursor to a more sensible location..
    let cmds = [ 
        \ 'set filetype=git_status_view'
        \ ,'setlocal syntax=gitcommit'
        \ ,"call search('# Changed but not updated:','e')"
        \ ]
    call tovl#scratch_buffer#ScratchBuffer({
          \ 'name' : 'git_status'
          \ ,'help' : help
          \ ,'getContent' : library#Function('return ["see :Help to read about r u a p mappings"] '
                                                  \ .'+ filter(split(tovl#runtaskinbackground#System(["git", "status"], {"status":"*"}),"\n"), "v:val !~ ''^#\\s*\\%((.*\\)\\?$''")')
          \ ,'cmds' : cmds
          \ ,'buftype' : 'nowrite'
          \ })
  endf

  fun! p.StatusViewAction(action)
    let list = matchlist(getline('.'), '^#\s*\%(\(\S*\):\)\?\s*\(\S*\)')
    let status = list[1]
    let file = list[2]
    if a:action == 'a'
      exec '!git add '.file
    elseif a:action  == 'u'
      exec '!git rm --cached '.file
    elseif a:action  == 'p'
      exec '!git add --patch '.file
    elseif a:action  == 'r'
      exec '!git rm '.file
    elseif a:action  == 'd'
      exec 'e tovl_exec://git?diff?'.file
    elseif a:action  == 'D'
      exec 'sp tovl_exec://git?diff?'.file
    elseif a:action  == 'c'
      CommitGit
    endif
  endf

  return p
endfunction
