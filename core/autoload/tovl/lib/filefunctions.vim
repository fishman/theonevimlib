"| if you pass dir a/b/c ["a/b/c","a/b","a"] will be returned
function! tovl#lib#filefunctions#WalkUp(path)
  let sep='\zs.*\ze[/\\].*'
  let result = [a:path]
  let path = a:path
  while 1
    let path=matchstr(path, sep)
    if path==""
      break
    endif
    call add(result, path)
  endwhile
  return result
endfunction

"func usage: WalkUpAndFind("mydir","tags")
"let tags=tovl#lib#files#filefunctions#WalkUpAndFind(a:path,"glob(tovl#lib#files#filefunctions#JoinPaths(path,'tags'))",1)
" consider using findfile of vim
" optional arg: 1 : continue even if a file was found
" "all" to return all visited pathes as well
function! tovl#lib#filefunctions#WalkUpAndFind(path,f_as_text,...)
  exec library#GetOptionalArg("option",string(0))
  let matches = []
  for path in tovl#lib#filefunctions#WalkUp(a:path)
    exec 'let item = '.a:f_as_text
    if (len(item) >0 )
      call add(matches, item)
      if option == 0
	break
      endif
    elseif option == "all" && type(option) == type("all")
      call add(matches, path)
    endif
  endfor
  if option == "all"
    return matches
  else
    if len(matches) > 0 
      if option == 1
        return matches
      else
        return matches[0]
      endif
    else
      return []
    endif
  endif
endfunction
