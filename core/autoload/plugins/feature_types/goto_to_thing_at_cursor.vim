" userinterface of core/autoload/tovl/ui/open_thing_at_cursor.vim
function! plugins#feature_types#goto_to_thing_at_cursor#PluginGotoThingAtCursor(p)
  let p = a:p
  let p['Tags'] = []
  let p['Info'] = "customize gf easily by adding your own functions returning matches. \n"
               \ ." If at least one match does exist on the filesystem that will be opened. \n"
               \ ." If there is no match, a new file will be opened (gf doesn't do this) \n"
               \ ." You can fallback to gF anytime (which does the same as gf but also recognizez line numbers)"
  let p['defaults']['tags'] = ['goto_thing_at_cursor']
  let p['defaults']['tags_buftype'] = {'nix' : ['goto_to_thing_at_cursor']}

  let p['loadingOrder'] = 50
  let p['feat_mapping'] = {
      \ 'goto_to_thing_at_cursor' : {
        \ 'lhs' : 'gf',
        \ 'rhs' : ':call tovl#ui#goto_thing_at_cursor#HandleOnThing()<cr>' 
      \ }
    \ }
  let p['featureTypes'] = {
      \ 'feat_GotoThingAtCursor' : {
        \ 'AddItem' : library#Function('plugins#feature_types#goto_to_thing_at_cursor#AddOnThingHandler'),
        \ 'DelItem' : library#Function('plugins#feature_types#goto_to_thing_at_cursor#DelOnThingHandler'),
        \ 'FromConfigApply' : library#Function('let ARGS[0]["buffer"] = 1')
      \ }}
  return p
endfunction

fun! plugins#feature_types#goto_to_thing_at_cursor#AddOnThingHandler(i)
  call tovl#ui#goto_thing_at_cursor#AddOnThingHandler(a:i['f'])
endf

fun! plugins#feature_types#goto_to_thing_at_cursor#DelOnThingHandler(i)
  call tovl#ui#goto_thing_at_cursor#RemoveOnThingHandler(a:i['f'])
endf
