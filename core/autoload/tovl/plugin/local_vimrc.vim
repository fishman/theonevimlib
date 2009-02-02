" implementation of the PluginLocalVimrc (core/autoload/plugins/tovl/local_vimrc.vim)
" plugin

" =========== project settings in external file ======================
" idea: have a tovl_project.vim file containing project settings
" to prevent abuse you'll be notified if the file was modified by somebody
" else. Then you can add it to the trusted list.
"
" if the file tovl_project.vim exists it will be sourced if it's known
" if not you are asked if you want to source it /show it
" known means: filesize (and optional md5sum if availible) does match
" TODO filesize is no longer used !

"known problems: the question is asked on the shell. You're out of luck if you
"don't use one (TODO: fix this by letting user choose to not choose and simply
"show a message.!)
"
"TODO: fix autocommand


fun! tovl#plugin#local_vimrc#ExtendPlugin()
  let d = {}

  fun! d.FileHash(path)
    return library#Hash(join(readfile(a:path,"\n")))
  endf

  function! d.SourceLocalRcs()
    echo "a"
    return

    let project_files = []
    for local_vimrc_name in eval(self.cfg.local_vimrc_names)
      call extend(project_files, tovl#lib#filefunctions#WalkUpAndFind(getcwd(),
        \ "glob(path.'/". local_vimrc_name ."')",1))
    endfor


    let known_project_files = config#GetC('project_vim_files','project_vim_files', {'default': {}})

    for full_path in project_files
      echom full_path
      continue

      " check and source
      if !has_key(known_project_files, full_path)
        let title = "unkown project file (".full_path.") found, availible actions: "
      else
        let known = known_project_files[full_path]
        let current = self.FileHash(full_path)
        if known == current
          call self.Log(1,'known project file '.full_path.' found, sourcing it')
          exec 'silent! source '.full_path
          continue
        else
          let title = "known but changed project file found, availible actions: "
        endif
      endif
      let actions =  [ "source and trust, remember permanently"
            \ , "edit and review"
            \ , "none" ]
      let choice = tovl#ui#choice#LetUserSelectIfThereIsAChoice(title, actions)
      if choice == "none"
        return 
      elseif choice == "edit and review"
        exec 'e '.full_path
      elseif choice == "source and trust, remember permanently"
        call self.SourceAndTrustProjectFile(full_path)
      endif
    endfor
  endfunction

  function! d.SourceAndTrustProjectFile(full_path)
    let hash = self.FileHash(a:full_path)
    call config#SetC('project_vim_files', ['project_vim_files', a:full_path], hash)
    exec 'source '.a:full_path
  endfunction

  return d
endf
