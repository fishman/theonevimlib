" minimal logging facility:
" optimized for speed
"
" shortcut for logging exceptions:
" if a message starts with "exception" the logging system will append
" FormatException() automatically

" keep it simple and fast, only 3 levels:
" 0 = error
" 1 = info
" 2 = debug

" context, level, msg
" interface for this instance:
" call tovl#log#Log('myplugin',0,'an error has occured')
fun! tovl#log#Log(...)
  let args = copy(a:000)
  if args[2][:len('exception')-1] == 'exception'
    let args[2] = args[2].tovl#log#FormatException()
  endif
  call call(s:logger.Log, args,s:logger)
endf

fun! tovl#log#GetLogger()
  return s:logger
endf

" replace instance by your own one
" it must implement the log function
fun! tovl#log#SetLogger(o)
  let s:logger = a:o
endf

" create instance
fun! tovl#log#NewLogObj()
  let o = {}
  let o.levelToStr = { 0 : "error", 1: "info", 2: "debug" }
  let o.level = 1
  let o.keep = 1000
  let o.max = 1500
  " maxLineLen is that long to ensure that the trace is added as well (-> debug_trace.vim)
  let o.maxLineLen = 4000
  let o.lines = []
  let o.lineCount = 0
  let o.whiteFilter = "self.level >= a:level"
  let o.nr = 1
  fun o.GetLines()
    return self.lines
  endfun
  fun! o.SetLevel(l)
    let self.level = a:l
    return self
  endf
  fun o.Log(context, level, msg)
    exec 'if !('.self.whiteFilter.')| return | endif'
    call add(self.lines, 
      \ [ strftime("%Y-%m-%d %H:%M:%S"),
        \ a:level,
        \ a:context[:self.maxLineLen],
        \ a:msg[:self.maxLineLen]
        \ ])
    let self.lineCount = self.lineCount +1
    if self.lineCount > self.max
      let self.lineCount = self.keep
      let self.lines = self.lines[:self.keep]
    endif
  endf
  return o
endf

call tovl#log#SetLogger(tovl#log#NewLogObj())

" use this in your own error messages..
fun! tovl#log#FormatException()
  return "\n".v:exception."\n".v:throwpoint."\n".
        \ join(plugins#tovl#debug_trace#FindPieces(matchstr(v:throwpoint,'.*\zs\S\+\.\.\S\+\ze'),{}),"\n")
endf
