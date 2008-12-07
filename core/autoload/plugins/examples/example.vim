" This example is the most simple one
" just define a user interface with one mapping echoing a customizable string

function! plugins#examples#example#PluginExample(p)
  " the default implementation of a:p from which we inherit 
  " can be found in tovl#plugin_management#NewPlugin() [1]

  " some general information about this plugin
  let p = a:p
  let p['Tags'] = ['example','demo']
  let p['Info'] = 'basic plugin demo showing how to override things'

  " == setting up default options ==
  let p['defaults']['string'] = "Hello!"
  " ft = filetype: empty = all
  " m = mode: "" = all
  " lhs, rhs, you know them (:h map)
  " self.s is a string representing this plugin (-> tovl#plugin_management#PluginDict())
  let p['mappings']['helloworld'] 
    \ = {'ft' : '', 'm':'n', 'lhs' : '<leader>hw', 'rhs' : ':echo '.p.s.'.cfg["string"]<cr>' }
  " == end                        ==

  let child = {}
  " these three functions only show that they exist :-)
  fun! child.vl#lib#vimscript#scriptsettings#Load()
    echom self.pluginName.": loading? yipiee!"
    call self.vl#lib#vimscript#scriptsettings#Load()
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

  return p.createChildClass(p.pluginName, child)
endfunction


" [1]
" you'll find more info about this minimal 
" duck typing when following tovl#obj#NewObject()

" also have a look at the move_copy plugin to see how you can add commands
