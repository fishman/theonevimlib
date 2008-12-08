" implementation of the template_systems/vl plugin

fun! tovl#template_systems#vl#ExtendPlugin()
  let d = {}

  "|func reads the last words before cursor and lets user choose an matching
  "|     template id from list. See example mapping
  "|     this also restores the paste option. This way you can use [%set paste%]
  "|+    in your template
  function! d.TemplateFromBufferWord()
    let paste = &paste
    let [b, a] = tovl#buffer#SplitCurrentLineAtCursor()
    let word = matchstr(b,'\w*$')
    let ids = split(self.CompleteTemplateId(word,0,0),"\n")
    let id = tovl#ui#choice#LetUserSelectIfThereIsAChoice("which template?", ids)
    if id == ""
      return 
    endif
    let text = repeat("\<bs>",len(word)).library#Call(self.TemplateById(id)['text'])
    return text."\<c-o>:set ".(paste ? "" : "no")."paste\<cr>"
  endfunction

  " returns list of { 'id' :..., 'text' : text or function }
  fun! d.AllTemplates()
    return tovl#list#Concat(
    \ map(copy(self.AllTemplateLocations()),
      \ 'library#Try(self.cfg.template_handlers, v:val)'
       \))
  endf

  function! d.TemplateById(id, ...)
    return filter(self.AllTemplates(), 'v:val["id"] == '.string(a:id))[0]
  endfunction

  "func arg list: list of [ "file", "template" ] to create
  "     optional arg is default values
  function! d.CreateFilesFromTemplates(list,...)
    exec library#GetOptionalArg('vars',string([]))
    for [file, template] in a:list
      exec 'sp '.file
      " remove everything which might have been written by filetype templates
      normal ggdG
      let template_text = d.TemplateById(template, vars)
      call self.InsertTemplate(template, vars)
    endfor
  endfunction

  function! d.InsertTemplate(id,...)
    exec library#GetOptionalArg('vars', string({}))
    let cursor_saved = getpos(".")
    let text_to_insert = d.TemplateTextById(a:id,vars)
    let @" = text_to_insert
    if len(text_to_insert) == 0
      echoe "strange. template resulted in empty string"
    endif
    exec "normal a\<c-r>\""
    call cursor(cursor_saved)
  endfunction

  function! d.TemplateIdList()
    return map(self.AllTemplates(), "v:val['id']")
  endfunction

  function! d.CompleteTemplateId(ArgLead,L,P)
    let ids = self.TemplateIdList()
    let matching_ids= filter(deepcopy(ids), 
       \ library#Call(self.cfg.quick_match_expr, [a:ArgLead]))
    call extend(matching_ids, filter(ids, "v:val =~".string(a:ArgLead)))
    let matching_ids = tovl#list#Uniq(matching_ids)
    return join(matching_ids,"\n")
  endfunction


  "|func this function can be used to be able to use omni completion
  "function! d."CompleteTemplate(findstart, base)
    "if a:findstart
      "[> locate the start of the word
      "let [bc,ac] = tovl#buffer#SplitCurrentLineAtCursor()
      "return len(bc)-len(matchstr(bc,'\%(\a\|\.\|\$\|\^\)*$'))
    "else
      "let ids = self.AllTemplates()
      "let matching_ids= filter(deepcopy(ids), 
         "\ library#Call(self.config.quick_match_expr(a:base)))
      "call extend(matching_ids, filter(ids, "v:val['id'] =~".string(a:base)))
      "[> let matching_ids = vl#lib#listdict#list#Unique(matching_ids)
      "echo len(matching_ids).' tepmlates found. choose on from list'
      "[> unfortunately we have to add the text to be inserted right now..
      "for entry in matching_ids
        "if complete_check()
          "return []
        "endif
        "let F = entry['get_template']
        "let template =   F(entry['value'])
        "let text_to_insert = template['text']
        "call complete_add( { 'word' : substitute(text_to_insert,"\n","\r",'g')
                         "\ , 'abbr' : entry['id']
                         "\ } )
                         "[>\ , 'menu': text_to_insert

      "endfor
    "endif
  "endfunction

  " =========================== adding and editing templates ====================
  fun! d.AllTemplateLocations()
    return tovl#list#Concat(map(
      \ copy(config#Get(self.pluginName.'#template_sources')),
      \ 'library#Call(v:val)'))
  endf

  fun! d.DirFromUser()
    let locations = map(filter(copy(self.AllTemplateLocations()),
          \ 'type(v:val)==4 && has_key(v:val, "directory")'),
          \ 'v:val["directory"]')
    return tovl#ui#choice#LetUserSelectIfThereIsAChoice(
      \ 'Add template to which directory?', locations)
  endf

  "|func   lets the user add a template to a directory
  function! d.TemplateNew()
    let ft = &ft
    let directory = self.DirFromUser()
    echo "remeber that you can use subdirectories, too"
    echo "use [% = selection %] to insert selected text. (te be implemented)"
    echo "    [% let vars['foo'] = <vimscript expession> %] to set a variable"
    echo "    [% = vars['foo'] %] to insert it "
    echo directory
    let file = input('new template file :', tlib#dir#CanonicName(directory),'file')
    if file == ''
      echo "user aborted"
    else
      exec 'sp '.file
      if &ft == ''
        " set filetype to the same filetype
        let &ft = ft
      endif
      runtime ftplugin/template*.vim
      put='[% set paste %]'
      1d
    endif
  endfunction

  "|func   lets the user edit a template from a directory
  function! d.TemplateEdit()
    let ft = &ft
    let directory = self.DirFromUser()
    let file = input('edit template file:', tlib#dir#CanonicName(directory),'file')
    if file == ''
      echo "user aborted"
    else
      exec 'sp '.file
      if &ft == ''
        let &ft = ft " set filetype to the same filetype
      endif
    endif
  endfunction

  return d
endf

"| preprocesses the text.
"| This means you can assign variables using [% foo=<some term>%] and use them
"| this way [% = vars['foo'] %]
"| optional argument specifies selected text which replaces [% = selection %] (TODO)
function! tovl#template_systems#vl#PreprocessTemplatetext(text, vars, ...)
  exec library#GetOptionalArg('selection',string('no optional arg given'))
  let vars = deepcopy(a:vars)
  let result = ""
  let parts = split(a:text, '\zs\ze\[%')
  for part in parts
    if part =~ '\[%.*%]'
      let subparts = split(part, '%\]\zs\ze')
      if len(subparts) > 2
        echoe "missing \[%"
      endif
      call add(subparts, '') " add empty string in case of '[% ... %]' without trailing text which will be added
      let vim_script_command = matchstr(subparts[0], '\[%\s*\zs.*\s*\ze%\]$')
      if vim_script_command =~ '^='
        let term = matchstr( vim_script_command, '=\s*\zs.*\ze\s*$')
        exec 'let text = '.term
        let result .= text.subparts[1]
      else
        if vim_script_command  =~ '^\s*let\s\+vars\[' || vim_script_command =~ '^set \%(no\)\=paste'
          " this term should be something like this: 
          exec vim_script_command
        else
          echoe "wrong assignment found: '".vim_script_command."'. Should be something like 'let vars[\"today\"] = ime(\"%Y %b %d %X\")! I do note execute this statement."
        endif
        let result .= subparts[1]
      endif
    else
      let result .= part
    endif
  endfor
  return [result, vars]
endfunction


" =============== template handlers ==========================

" directory template handler
" ------------------------
function! tovl#template_systems#vl#GetDirectoryTemplate(path, vars, use_vim_preprocessor_using_exec)
  let text = join(readfile(expand(a:path)),"\n")
  return a:use_vim_preprocessor_using_exec
    \ ?  tovl#template_systems#vl#PreprocessTemplatetext(text, a:vars)[0]
    \ : text
endfunction

function! tovl#template_systems#vl#DirectoryTemplateHandler( template )
  if type(a:template) != 4 || !has_key(a:template, 'directory') |
    throw "wrong handler, expected dict with key directory, got ".string(a:template)
  endif
  let directory = a:template['directory']
  let template_files = split(globpath(expand(directory),'**/*'),"\n")
  " no directories!
  call filter(template_files, 'filereadable(v:val)')
  let templates = []
  for file in template_files
    call add(templates, { 'id' : matchstr(file, '^\%('.escape(directory,'\\').'\)\=[/\\]\=\zs.*\ze'),
                        \ 'text' : library#Function('tovl#template_systems#vl#GetDirectoryTemplate',
                               \ { 'args' : [file, {}, get(a:template,'use_vim_preprocessor_using_exec', 0) ]})
                      \ })
  endfor
  return templates
endfunction


" handles template given directly
function! tovl#template_systems#vl#TemplateGivenDirectlyHandler(template)
  if type(a:template) == 4 && has_key(a:template, 'template')
    let template = a:template['template']
    return [{ 'id' : template['id']
            \ , 'text' : template['text']
            \ }]
endfunction

