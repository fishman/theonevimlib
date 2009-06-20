" see also PluginSyntaxChecker
function! plugins#filetype#flex#PluginFlexSupport(p)
  let p = a:p
  let p['Tags'] = ["flex", "javascript"]
  let p['Info'] = "Run flex compiler in background"
  let p['defaults']['tags'] = ['flex_support']
  let p['defaults']['tags_buftype'] = {'xml': [ 'flex_support' ], 'mxml' : ['flex_support']}
  let p['defaults']['mxmlc_executable'] = 'mxmlc'
  let p['defaults']['run_swf_in_browser'] = string(['firefox', '-new-window', '$SWF'])

  " I don't use atlas. How to really fix this?
  let p['defaults']['overwrite_atlas_set_ft_to_actionscript'] = 1

  let p['feat_GotoThingAtCursor'] = {
      \ 'jump_to_path' : {
        \ 'buffer' : 1
        \ ,'f' : library#Function("return ". p.s .".LocationList()")}}


  fun! p.LocationList()
    let res = [expand(expand('%:h').'/'.matchstr(expand('<cWORD>'),'[^;()[\]]*'))
           \ , expand('%:h').'/'.matchstr(getline('.'), 'import\s*\zs[^;) \t]\+\ze')
           \ ]
    return res
  endf

  "fun! p.mxmlFile()
  "  if !exists('g:mxml_file')
  "    let files = split(glob("*.mxml"),"\n")
  "    if len(files) == 0
  "      let g:mxml_file = input("no mxml file found in current directory, set it")
  "    else
  "      let g:mxml_file = tovl#ui#choice#LetUserSelectIfThereIsAChoice("choose .mxml project file", 
  "    endif
  "  endif
  "  return g:mxml_file
  "endfun

  fun! p.RunMXMLActionString()
    " without -incremental it takes about 12secs here, with only 2!
    return 'silent! wa <bar>'
          \ . 'call tovl#runtaskinbackground#Run('.string(
                \ {'cmd': [self.cfg.mxmlc_executable, "-incremental=true", expand('%')],
                 \ 'ef' : 'plugins#tovl#errorformats#PluginErrorFormats#mxmlc', 'onFinishCallbacks' : ['cope']}).')'
  endf

  fun! p.RunSWFActionString()
    if expand('%:e') != "mxml"
      throw "current file beeing an .mxml expected"
    endif
    " keep it simple. Assume the current file is an .mxml file
    let swf = expand('%:p:r').'.swf'
    return 'call tovl#runtaskinbackground#Run('.string(
                \ {'cmd': map(eval(self.cfg.run_swf_in_browser), 'substitute(v:val, "\\$SWF",'.string(swf).',"")'),
                 \ 'ef' : 'plugins#tovl#errorformats#PluginErrorFormats#mxmlc', 'onFinishCallbacks' : ['cope']}).')'
  endf
  let p['feat_action'] = {
        \ 'run_mxmlc' : {
        \   'key': 'run_mxmlc',
        \   'description': "runs mxmlc <this file> and loads the result into the quickfix window",
        \   'action' : library#Function('return '. p.s .'.RunMXMLActionString()')
        \ },
        \ 'run_result_in_browser' : {
        \   'key': 'run_mxmlc_result_in_browser',
        \   'description': "runs the .swf created by run_mxmlc in a browser",
        \   'action' : library#Function('return '. p.s .'.RunSWFActionString()')
        \ }
      \ }

  let child = {}
  fun! child.Load()
    " set filetype
    call self.Au({'events': 'BufRead,BufNewFile', 'pattern': '*.mxml',
          \ 'cmd': 'silent! setlocal ft=mxml'})
    " add runtime stuff for xml files
    call self.Au({'events': 'BufRead,BufNewFile', 'pattern': '*.mxml',
          \ 'cmd': 'runtime! ftplugin/xml.vim ftplugin/xml_*.vim ftplugin/xml/*.vim'})
    " set syntax to xml
    call self.Au({'events': 'BufRead,BufNewFile', 'pattern': '*.mxml',
          \ 'cmd': 'setlocal syntax=xml'})

    if self.cfg.overwrite_atlas_set_ft_to_actionscript

      call self.Au({'events': 'BufRead,BufNewFile', 'pattern': '*.as',
            \ 'cmd': 'setlocal filetype=actionscript'})

      " use js syntax for now (FIXME)
      call self.Au({'events': 'BufRead,BufNewFile', 'pattern': '*.as',
            \ 'cmd': 'set syntax=javascript'})

    endif

    call self.Parent_Load()
  endf
  return p.createChildClass(child)
endfunction
