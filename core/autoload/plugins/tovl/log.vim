" interface for autoload/tovl/log.vim
" keep it fast and simple, yet powerful.
function! plugins#tovl#log#PluginLog(p)
  let p = a:p
  let p['Tags'] = ['logging']
  let p['Info'] = "interface to view tovl log"

  " run this to fix prefixes of autoload functions (remember that you can use undo.. :-)
  let p['mappings']['insert_template'] = {
    \ 'ft' : '', 'm':'n', 'lhs' : '<m-l><m-o><m-g>',
    \ 'rhs' : ':call plugins#tovl#log#ShowTOVLLog()<cr>' 
    \ }

  let child = {}
  fun! child.Load()
    command! -nargs=0 TOVLLog :call plugins#tovl#log#ShowTOVLLog()
    call self.Parent_Load() 
  endfunction
  fun! child.Unload()
    delc TOVLLog
    call self.Parent_Unload()
  endf
  return p.createChildClass(child)
endfunction

fun! plugins#tovl#log#ShowTOVLLog()
  call tovl#scratch_buffer#ScratchBuffer({
        \ 'name' : "TOVL-Log",
        \ 'getContent' : library#Function("return tovl#list#Concat(map(tovl#log#GetLogger().GetLines(),'[v:val[0].'' ''.v:val[1].'' ''.v:val[2].'':'',v:val[3]]'))"),
        \ 'hepl' : [
          \ "Use :GetContents to refresh the view",
          \ "I recommend the filter lines mappings from various or TToC for filtering"
          \ ]
        \ })
  setlocal nowrap
  syn match Error "^....-..-.. ..:..:.. 0.*"
  syn match Identifier "^....-..-.. ..:..:.. 1.*"
endf
