" This example is the most simple one
" just define a user interface with one mapping and a command echoing a customizable string

function! plugins#examples#example#PluginExample(p)
  " the default implementation of a:p from which we inherit 
  " can be found in tovl#plugin_management#NewPlugin() [1]

  " some general information about this plugin
  let p = a:p
  let p['Tags'] = ['example','demo']
  let p['Info'] = 'basic plugin demo showing how to override things and how to write plugins in general'

  " == setting up default options ==
  let p['defaults']['string'] = "Hello!"

  " global and local mappings and commands
  " p.s : [2]
  let p['feat_mapping'] = {
      \ 'helloworld_global' : {
        \ 'tags' : ['example'],
        \ 'm':'n',
        \ 'lhs' : '\hw',
        \ 'rhs' : ':echo '.p.s.'.cfg["string"]." - from global mapping"<cr>' 
        \ },
     \ 'helloworld_buffer' : {
        \ 'tags' : ['example'],
        \ 'm':'n',
        \ 'buffer' : 1,
        \ 'lhs' : '\bhw',
        \'rhs' : ':echo '.p.s.'.cfg["string"]." - from buffer mapping"<cr>'
        \ }
      \ }
  let p['feat_command'] = {
      \ 'helloworld_global' : {
          \ 'tags' : ['example'],
          \ 'name' : 'Example',
          \ 'cmd' : 'echo '.p.s.'.cfg["string"]." - from global command"' 
      \ },
      \ 'helloworld_buffer' : {
        \ 'tags' : ['example'],
        \ 'name' : 'BufExample',
        \ 'buffer' : 1,
        \ 'cmd' : 'echo '.p.s.'.cfg["string"]." - from buffer cmd"' 
      \ }
    \ }

  " For this to work you must have enabled the feat_action feature
  let p['feat_action'] = {
        \ 'print_hello_world_example_action' : {
        \   'key': 'example_hw',
        \   'description': "prints hello world after you've mapped this action to a key",
        \   'action' : 'echo "hello world"'
        \ }}

  " when activating this plugin add global feature tag example
  let p['defaults']['tags'] = ['example']
  " automatically add tag "example" to buffers having either filetype help or vim
  let p['defaults']['tags_filetype'] = {'vim' : ['example'], 'help' : ['example']}

  " == overriding default plugin behaviour == "
  " see [1]

  let child = {}
  " these three functions only show that they exist :-)
  " You can override them this way and change their behaviour
  fun! child.Load()
    echom self.pluginName.": loading? yipiee!"
    " you could do arbitrary stuff here.. such as setting up
    " make file compilation if a Makifle is found in the current directory
    " example : core/autoload/plugins/language_support/haskell.vim
    call self.Parent_Load()
    echom self.pluginName.": loaded"
  endf
  fun! child.Unload()
    echom self.pluginName.": unloaded! goodbye!"
    call self.Parent_Unload()
  endf
  fun! child.OnConfigChange()
    echom self.pluginName.": My configuration has changed!"
    call self.Parent_OnConfigChange()
  endf

  return p.createChildClass(child)
endfunction


" Does your plugin contain much code?
" Have a look at template_systems/vl.vim to see how to load a small "class"
" loading more code on demand.

" [1]
" you'll find more info about this minimal 
" duck typing when following tovl#obj#NewObject()

" [2]
" p.s is a string which determines this plugin
" Have a look at the options in TOVLConfig to see its expansion
