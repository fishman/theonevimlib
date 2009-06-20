" author: Marc Weber
"
" TODO : think about adding context etc? the list view does support this all
"  unfortunately this implementation should not be used on buffers having more
"  than 2.000 lines :-( It gets too slow
"
"  idea taken from my earlier script, vimtlib (Tom Link) and the outline view
"  which can be found in Eclipse (c-o mapping). You should also try the TToC
"  command found in vimtlib and use the one which you like more :)

function! plugins#buffer#tovl_toc#PluginTOVL_ToC(p)
  let p = a:p
  let p['Tags'] = ['outline','table of contents']
  let p['Info'] = "simple table of contents user interface based on ideas of TToC by Tomas Link"
		\ . "and my previous older outline by regex script"

  " put cursor on autolad function and press gf to jump to the file or to create
  " a new file.
  let p['defaults']['tags'] = ['tovl_toc']
  let p['defaults']['filetypes'] = {}
  let ft = p['defaults']['filetypes']
  " these regex can still be enhanced. I've added them so that something is
  " there
  let ft['js'] = '\%(\<function\>\|\<Class\>\|^var\>\|^\S\+\s\)'
  let ft['vim'] = '^\s*\%(fun\|com\|au\S*\)'
  let ft['php'] = '^\(\%(static\|public\|abstract\|protected\|private\)\s\+\)*\%(function\|class\)'
  let ft['ant'] = '^\s*<target'
  let ft['sql'] = '^\s*\c\%(\SELECT\|CREATE\|UPDATE\|DESCRIBE\|DROP\|ALTER\|INSERT\).*'
  let ft['perl'] = '^\s*sub' " this is a stub
  let ft['python'] = '^\s*\%(def\|class\)' " this is a stub
  let ft['haskell'] = '^\s*\%(\%(\zs\%(where\)\@!\%(\l\w*\)\ze\%(\s\+\%(\S\+\)\)*\s*=\)\|\%(\%(\S\+\)\s*`\zs\%(where\)\@!\%(\l\w*\)\ze`\s*\%(\S\+\)\s*=\)\)'
  let ft['javascript'] = 'function'
  " actionscript isn't prfect yet ..
  let ft['actionscript'] = 'private\|public\|include\|class\|interface\|propert\%(y\|ies\)'
  let ft['make'] = '^[^: ]\+\s*:.*\|include'


  let p['feat_mapping'] = {
    \ 'toc_by_regex' : {
      \ 'lhs' : '<m-r><m-o>',
      \ 'rhs' : ':call '.p.s.'.ToC(input("regex for toc:"))<cr>'
      \ },
    \ 'toc_by_regex_default' : {
      \ 'lhs' : '<m-t><m-o>',
      \ 'rhs' : ':call '.p.s.'.ToCFiletype()<cr>'
      \ }}
  let p['feat_command'] = {
    \ 'toc_by_regex' : {
      \ 'name' : 'TOVLToc',
      \ 'attrs' : '-nargs=1',
      \ 'cmd' : 'call '.p.s.'.ToC(<q-args>)'
      \ }}

  fun p.ToCFiletype()
    if exists('self.cfg.filetypes') && has_key(self.cfg.filetypes, &filetype)
      call self.ToC(self.cfg.filetypes[&filetype])
    else
      echoe "not default toc regex defined for fileltype ".&filetype." :-( , do you like to provide one?"
    endif
  endfun
  fun p.ToC(regex)
    let nr=1
    let lines = []
    for l in getline(0,line('$'))
      call add(lines, {'nr': nr, 'line' :l})
      let nr = nr +1
    endfor
    call tovl#ui#filter_list#ListView({
	  \ 'aligned' : 0,
	  \ 'filter' : [{'keep' : 1, 'regex' : a:regex }],
	  \ 'keys' : ['nr','line'],
	  \ 'number' : 1,
	  \ 'selectByIdOrFilter' : 1,
	  \ 'Continuation' : library#Function('exec ARGS[0]["nr"]'),
	  \ 'items' : lines,
	  \ 'syn_cmds' : ['runtime! syntax/'.&filetype.'.vim'],
          \ 'cmds' : ['normal zR'],
          \ 'cursorAt' : line('.') -1
	  \ })
  endfun
  return p
endfunction
