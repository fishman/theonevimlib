" =========== project settings in external file ======================
" idea: have a vl_project.vim file containing project settings
" to prevent abuse you'll be notified if the file was modified by somebody
" else. Then you can add it to the trusted list.
"
" if the file vl_project.vim exists it will be sourced if it's known
" if not you are asked if you want to source it /show it
" known means: filesize (and optional md5sum if availible) does match
" TODO filesize is no longer used !

"known problems: the question is asked on the shell. You're out of luck if you
"don't use one (TODO: fix this by letting user choose to not choose and simply
"show a message.!)
"
"TODO: fix autocommand


" usage : 
" add call tovl#lib#ide#ide#AddProjectVimfileStart()
" to your ~/.vimrc (TODO create a tovl plugin)
" write a vl_repo.vim file and add vim commands
" run vim within that or a subdir of that file

fun! s:FileHash(path)
  return library#Hash(join(readfile(a:path,"\n")))
endf

fun! s:Log(...)
  call library#Call(library#Function('tovl#log#Log'), ["ide"] + a:000)
endf

let s:project_filename = 'vl_project.vim'

function! tovl#lib#ide#ide#AddProjectVimfileStart()

  exec 'command! ProjectVimfileEdit :e '.s:project_filename
  ".' <bar>  echo "after writing this file it will be automatically sourced and trusted by autocommand" <bar> exec "u BufWritePost ".expand('%')." call vl#lib#ide#ide#SourceAndTrustProjectFile()"'
  silent! let project_files = tovl#lib#filefunctions#WalkUpAndFind(getcwd(), "glob(path.'/".s:project_filename."')",1)
  
  for full_path in project_files
    " check and source
    let known_project_files = config#GetC('project_vim_files','project_vim_files', {'default': {}})
    if !has_key(known_project_files, full_path)
      let title = "unkown project file (".full_path.") found, availible actions: "
    else
      let known = known_project_files[full_path]
      let current = s:FileHash(full_path)
      if known == current
        call s:Log(1,'known project file '.full_path.' found, sourcing it')
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
      exec 'e '.s:project_filename
    elseif choice == "source and trust, remember permanently"
      call tovl#lib#ide#ide#SourceAndTrustProjectFile(full_path)
    endif
  endfor
endfunction

function! tovl#lib#ide#ide#SourceAndTrustProjectFile(full_path)
  let hash = s:FileHash(a:full_path)
  call config#SetC('project_vim_files', ['project_vim_files', a:full_path], hash)
  exec 'source '.a:full_path
endfunction
