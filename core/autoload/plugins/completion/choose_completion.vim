function!  plugins#completion#choose_completion#PluginChooseCompletionFunc(p)
  let p = a:p
  let p['Tags'] = ['completion']
  let p['Info'] = "interface for tovl/ui/multiple_completions.vim"
  " run this to fix prefixes of autoload functions (remember that you can use undo.. :-)
  let p['mappings']['fix_funtion_prefixes'] = {
    \ 'ft' : 'vim', 'm':'n', 'lhs' : '',
    \ 'rhs' : ':ChooseCompletionFunc<cr>' }
  let child = {}
  fun! child.Load()
    command! ChooseCompletionFunc call tovl#ui#multiple_completions#ChooseCompletionFunc()
    call self.Parent_Load()
  endf
  fun! child.Unload()
    delc ChooseCompletionFunc
    call self.Parent_Unload()
  endf
  return p.createChildClass(p.pluginName, child)
endfunction
