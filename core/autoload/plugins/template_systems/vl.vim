" description:
" template_sources: list of functions returning lists of template sources
" template_handlers: They know how to extract lists of templates from the
"                     sources.
" a template is a simple dict { 'id' : name, text : function ref }
" The text is then inserted by the mapping <c-r>=....<cr> see below
"
" Probably the DirectoryTemplateHandler is all you need. You pass a
" {'directory' : dir } dict as source. The handler will scan that directory
" adding all files as template to the list of templates
"
" The Template{New,Edit} commands will only take those { 'directory' : ..}
" sources into account.

" If you enable use_vim_preprocessor_using_exec you can use
"   [% = strftime("%Y-%m-%d %H:%M:%S") ]
" to insert a current timestamp. However you should be aware that someone else
" can run arbitrary vim expressions such as [% let var = system('rm -fr /') ].
" So only enable this feature if only you have access to your templates!

" the implementation can be found in
function! plugins#template_systems#vl#PluginVL_Templates(p)
  let p = a:p
  let p['Tags'] = ['templates','vimscript']
  let p['Info'] = "simple customizable template system. The default implementation lets you even evaluate some vimscript snippets.. "

  " run this to fix prefixes of autoload functions (remember that you can use undo.. :-)
  let p['mappings']['insert_template'] = {
    \ 'ft' : '', 'm':'i', 'lhs' : '<m-s-t>',
    \ 'rhs' : '<c-r>='.p.s.'.loadMissing().TemplateFromBufferWord()<cr>' }

  " the result of this list will be read by a fitting handler
  " (template_handlers).
  let p['defaults']['template_sources'] =
      \ [library#Function('return [{ "directory":config#DotVim()."/tovl_templates/".&ft, "use_vim_preprocessor_using_exec" :0}]')]
  let p['defaults']['template_handlers'] =
       \ ['tovl#template_systems#vl#DirectoryTemplateHandler']
  let p['defaults']['quick_match_expr'] =
        \ library#Function('return "v:val =~ ".string(tovl#ui#match#AdvancedCamelCaseMatching(ARGS[0]))')
  
    " inoremap <m-t> <c-r>=tovl#template_vl#lib#template#template#TemplateTextById(input("template id :",'',"custom,tovl#template_vl#lib#template#template#CompleteTemplateId"))<cr>
  
  let p['missing'] = [library#Function('tovl#template_systems#vl#ExtendPlugin')]

  let child = {}
  fun! child.Load()
    " first let's the user choose to which template directory he likes to add
    " a new template. Then inserts that path into cmd line so that you can
    " write your new template
    call self.LogExec(1,'command', "command! TemplateNew :call ".self.s.".loadMissing().TemplateNew()<cr>")
    call self.LogExec(1,'command', "command! TemplateEdit :call ".self.s.".loadMissing().TemplateEdit()<cr>")
    "command! -buffer -nargs=1 -complete=custom,CompleteTemplateId TemplateInsert  :call tovl#template_systems#template#InsertTemplate(<f-args>)
    call self.Parent_Load() 
  endfunction
  fun! child.Unload()
    delc TemplateNew
    delc TemplateEdit
    call self.Parent_Unload()
  endf
  return p.createChildClass(child)
endfunction
