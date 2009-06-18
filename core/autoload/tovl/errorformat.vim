" Gets an error format from the configuration
" see  also autoload/plugins/tovl/error_formats.vim

fun! tovl#errorformat#SetErrorFormat(id)
  exec 'silent! set efm='.join(map(split(
        \ config#Get(a:id),"\n")
        \ , 'tovl#errorformat#EscapePattern(v:val)'),',')
endf

function! tovl#errorformat#EscapePattern(p)
  return escape(substitute(a:p,',','\\,','g'),' \,|"')
endfunction
