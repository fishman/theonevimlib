" =========== scratch buffer =========================================
" a scratch buffer is a temporary buffer where the user can enter some text
" It can be used to get commit messages, edit configuration options and so on

function! tovl#scratch_buffer#KeepIntactLineNr()
  let i = 0
  while getline(i)!= b:keepIntact && i < line('$')
    let i = i+1
  endwhile
  if i > line('$')
    return -1
  else
    return i
  endif
endfunction

" opens a buffer and runs an action when the buffer is written
" keys: 
"  name :   the name of the buffer
"  onWrite : will be called on write
"            onWrite is responsible for setlocal nomodified to indicate that
"            saving has been successful
"  help  : callback returning additional information lines
"  getContent : callback returning lines
"  cmds    : extra commands to be run (optional)
"  buftype : ...
function! tovl#scratch_buffer#ScratchBuffer(opts)
  let a:opts['name'] = get(a:opts,'name', 'strach_buffer_without_name')
  exec 'sp '.escape(a:opts['name'],' ')
  let b:settings = a:opts
  setlocal buftype=acwrite
  command! -buffer -nargs=0 GetContents call tovl#scratch_buffer#GetContents()
  command! -buffer -nargs=0 Help call tovl#scratch_buffer#Help()

  " setup write notification
  au TOVLWrite BufWriteCmd <buffer> call tovl#scratch_buffer#Write()

  exec 'setlocal buftype='.get(a:opts, 'buftype', '')

  GetContents

  " mark buffer as not modified
  setlocal nomodified

  " run addittional commands
  for cmd in get(a:opts,'cmds',[])
    exec cmd
  endfor
  echo "type :Help for help"
endfunction

" =========== utility functions ======================================

function! tovl#scratch_buffer#Write()
  if has_key(b:settings, 'onWrite')
    call library#Call(b:settings['onWrite'])
  else
    echo "don't know how to write. Option hasn't been passed"
  endif
endfunction

function! tovl#scratch_buffer#GetContents()
  if has_key(b:settings, 'getContent')
    normal ggdG
    call append(0, library#Call(b:settings['getContent']))
  else
    echo "don't know how to refresh buffer contents"
  endif
endfunction

function! tovl#scratch_buffer#Help()
  let help = ["use :GetContents to reload contents, ZZ or :w(q) to write and quit"
          \ ,""
          \ ,"Help for this scratch buffer:"
          \ ,"=======================================================","",""]
    \ + library#Call(get(b:settings, 'help', []))
  call tovl#scratch_buffer#ScratchBuffer({
        \ 'name' : "return Help of ".b:settings['name'],
        \ 'getContent' : help
        \ })
endfunction
