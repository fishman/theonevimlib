" does automtic escaping for you
function! tofl#buffer#Put(lines, ...)
   exec library#GetOptionalArg('line',string(''))
   if len(a:lines) == 0
     return 
   endif
   for l in a:lines
     exec line."put='".substitute(escape(l, '|"'),"'","''",'g')."'"
     let line = ''
   endfor
endfunction
