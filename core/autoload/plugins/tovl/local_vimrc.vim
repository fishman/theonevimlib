" usage:
"
" create tovl_project.vim within your project directory and restart vim.
" also see core/autoload/tovl/plugin/local_vimrc.vim

" the implementation can be found in
function! plugins#tovl#local_vimrc#PluginLocalVimrc(p)
  let p = a:p
  let p['Tags'] = ['templates','vimscript']
  let p['Info'] = "source a project specific vim configuration file after confirmation only walking up the path"

  let p['loadingOrder'] = 200

  let p['defaults']['tags'] = ['local_vimrc']
  let p['defaults']['local_vimrc_names'] = string(['tovl_project.vim'])

  " :e local_vimrc_name
  let p['feat_command'] = {
    \ 'edit_local_vimrc' : {
      \ 'name' : 'LocalVimrcFileEdit',
      \ 'attrs' : '-nargs=0',
      \ 'cmd' : "exec 'e '.".p.s.".eval(cfg.local_vimrc_names)[0]<cr>"
      \ }
    \ }
  let child = {}
  fun! child.Load()
    call self.SourceLocalRcs()
    call self.Parent_Load()
  endf

  fun! child.FileHash(path)
    return library#Hash(join(readfile(a:path,"\n")))
  endf

  function! child.SourceLocalRcs()

    let project_files = []
    for local_vimrc_name in eval(self.cfg.local_vimrc_names)
      call extend(project_files, tovl#lib#filefunctions#WalkUpAndFind(getcwd(),
        \ "glob(path.'/". local_vimrc_name ."')",1))
    endfor


    let known_project_files = config#GetC('project_vim_files','project_vim_files', {'default': {}})

    for full_path in project_files
      " check and source
      if !has_key(known_project_files, full_path)
        let title = "unkown project file (".full_path.") found, availible actions: "
      else
        let known = known_project_files[full_path]
        let current = self.FileHash(full_path)
        if known == current
          call self.Log(1,'known project file '.full_path.' found, sourcing it')
          try
            exec 'source '.full_path
          catch /.*/
            call self.Log(0, 'exception: error while sourcing '.full_path)
          endtry
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

  function! child.SourceAndTrustProjectFile(full_path)
    let hash = self.FileHash(a:full_path)
    call config#SetC('project_vim_files', ['project_vim_files', a:full_path], hash)
    exec 'source '.a:full_path
  endfunction

  return p.createChildClass(child)
endfunction
