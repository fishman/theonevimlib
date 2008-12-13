" interface for autoload/tovl/log.vim
" keep it fast and simple, yet powerful.
function! plugins#tovl#log#PluginLog(p)
  let p = a:p
  let p['Tags'] = ['logging']
  let p['Info'] = "interface to view tovl log. Also see plugin TOVL_Config"

  let p['defaults']['tags'] = ['tovl_log']
  " run this to fix prefixes of autoload functions (remember that you can use undo.. :-)
  let p['feat_mapping'] = {
    \ 'show_tovl_log' : {
      \ 'm':'n',
      \ 'lhs' : '<m-l><m-o><m-g>',
      \ 'rhs' : ':call plugins#tovl#log#ShowTOVLLog()<cr>' ,
      \ }
    \ }
  let p['feat_command'] = {
    \ 'show_tovl_log' : {
      \ 'name' : 'TOVLLog',
      \ 'cmd' : 'call plugins#tovl#log#ShowTOVLLog()',
      \ 'attrs' : '-nargs=0',
      \ }
    \ }
  return p
endfunction

fun! plugins#tovl#log#ShowTOVLLog()
  call tovl#scratch_buffer#ScratchBuffer({
        \ 'name' : "TOVL-Log",
        \ 'getContent' : library#Function("return tovl#list#Concat(map(tovl#log#GetLogger().GetLines(),'[v:val[1].'' ''.v:val[0].'' ''.v:val[2].'':'']+split(v:val[3],\"\\n\")'))"),
        \ 'hepl' : [
          \ "Use :GetContents to refresh the view",
          \ "I recommend the filter lines mappings from various or TToC for filtering"
          \ ]
        \ })
  setlocal nowrap
  syn match Error "^0 ....-..-.. ..:..:.. .*"
  syn match Identifier "^1 ....-..-.. ..:..:.. .*"
endf
