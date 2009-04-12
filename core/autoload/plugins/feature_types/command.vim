" userinterface of core/autoload/tovl/ui/open_thing_at_cursor.vim
function! plugins#feature_types#command#PluginCommand(p)
  let p = a:p
  let p['Tags'] = []
  let p['Info'] = "This feature type adds the commands."
  let p['loadingOrder'] = 45
  fun! p.AddCommand(i)
    call self.LogExec(2, '+command',
       \ 'command! '.(get(a:i, 'buffer',0) ? '-buffer' : '').' '.
       \ (get(a:i, 'complete',0) ? '-complete='. a:i.complete : '').' '.
       \ get(a:i,'attrs','').' '.
       \ a:i['name'].' '.
       \ a:i['cmd'])
  endf
  fun! p.DelCommand(i)
    "call self.LogExec(2, '-command  ', 'delc! '.a:i['name'])
  endf
  let p['defaults']['configDummy'] = "make this plugin load cause it hasn't any options"
  let p['featureTypes'] = {
      \'feat_command' : {
        \ 'AddItem' : library#Function(p.AddCommand, {'self' : p}),
        \ 'DelItem' : library#Function(p.DelCommand, {'self' : p}),
      \ }}
  return p
endfunction
