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
  " ft = filetype: empty = all
  " m = mode: "" = all
  " lhs, rhs, you know them (:h map)
  " self.s is a string representing this plugin (-> tovl#plugin_management#PluginDict())
  let p['mappings']['helloworld'] 
    \ = {'ft' : '', 'm':'n', 'lhs' : '\hw', 'rhs' : ':echo '.p.s.'.cfg["string"]<cr>' }
  " == end                        ==

  let child = {}
  " these three functions only show that they exist :-)
  fun! child.Load()
    echom self.pluginName.": loading? yipiee!"
    call self.LogExec(1,'command', 'command Example :echo '.self.s.'.cfg["string"]')
    call self.Parent_Load()
    echom self.pluginName.": loaded"
  endf
  fun! child.Unload()
    call self.LogExec(1,'', 'delc Example')
    echom self.pluginName.": unloaded! goodbye!"
    call self.Parent_Unload()
  endf
  fun! child.OnConfigChange()
    echom self.pluginName.": My configuration has changed!"
    call self.Parent_OnConfigChange()
  endf

  return p.createChildClass(child)
endfunction


" [1]
" you'll find more info about this minimal 
" duck typing when following tovl#obj#NewObject()

" also have a look at the move_copy plugin to see how you can add commands
"
" Does your plugin contain much code?
" Have a look at template_systems/vl.vim to see how to load a small "class"
" loading more code on demand.
