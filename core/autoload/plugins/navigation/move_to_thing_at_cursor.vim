" userinterface of tovl/ui/multiple_completions.vim
function! plugins#navigation#move_to_thing_at_cursor#PluginMoveToThingAtCursor(p)
  let p = a:p
  let p['Tags'] = []
  let p['Info'] = "customize gf easily by adding your own functions returning matches. \n"
               \ ." If at least one match does exist on the filesystem that will be opened. \n"
               \ ." If there is no match, a new file will be opened (gf doesn't do this) \n"
               \ ." You can fallback to gF anytime (which does the same as gf but also recognizez line numbers)"
  let p['mappings']['move_to_thing_at_cursor'] = {
    \ 'ft' : '', 'm':'n', 'lhs' : 'gf',
    \ 'rhs' : ':call tovl#ui#open_thing_at_cursor#HandleOnThing()<cr>' }
  return p
endfunction
