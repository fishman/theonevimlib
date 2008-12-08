" minimal logging facility:
" optimized for speed

" keep it simple and fast, only 3 levels:
" 0 = error
" 1 = info
" 2 = debug

" context, level, msg
" interface for this instance:
" call tovl#log#Log('myplugin',0,'an error has occured')
fun! tovl#log#Log(...)
  call call(s:logger.Log, a:000,s:logger)
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
  let o.level = 0
  let o.keep = 1000
  let o.max = 1500
  let o.maxLineLen = 200
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
