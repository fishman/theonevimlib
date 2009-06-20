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
"
"
" !!! consider using scriptmate instead

" the implementation can be found in
function! plugins#template_systems#tovl_template#PluginTOVL_Template(p)
  let p = a:p
  let p['Tags'] = ['templates','vimscript']
  let p['Info'] = "simple customizable template system. The default implementation lets you even evaluate some vimscript snippets.. "

  let p['defaults']['tags'] = ['tovl_templates']
  " run this to fix prefixes of autoload functions (remember that you can use undo.. :-)
  let p['feat_mapping'] = { 'insert_template' : {
    \ 'm':'i', 'lhs' : '<m-s-t>',
    \ 'rhs' : '<c-r>='.p.s.'.loadMissing().TemplateFromBufferWord()<cr>' }}


  " first let's the user choose to which template directory he likes to add
  " a new template. Then inserts that path into cmd line so that you can
  " write your new template
  let p['feat_command'] = {
    \ 'new_template' : {
      \ 'name' : 'TemplateNew',
      \ 'attrs' : '-nargs=0',
      \ 'cmd' : "call ".p.s.".loadMissing().TemplateNew()<cr>"
      \ },
    \ 'edit_template' : {
      \ 'name' : 'TemplateEdit',
      \ 'attrs' : '-nargs=0',
      \ 'cmd' : "call ".p.s.".loadMissing().TemplateEdit()<cr>"
      \ }}

  " the result of this list will be read by a fitting handler
  " (template_handlers).
  let p['defaults']['template_sources'] =
      \ [library#Function('return [{ "directory":config#DotVim()."/tovl_templates/".&ft, "use_vim_preprocessor_using_exec" :0}]')]
  let p['defaults']['template_handlers'] =
       \ [library#Function('tovl#template_systems#vl#DirectoryTemplateHandler')]
  let p['defaults']['quick_match_expr'] =
        \ library#Function('return "v:val =~ ".string(tovl#ui#match#AdvancedCamelCaseMatching(ARGS[0]))')
  
  let p['missing'] = [library#Function('tovl#template_systems#vl#ExtendPlugin')]
  return p
endfunction
