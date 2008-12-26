" provide a list of actions (such as running this .sh .php .python .pl file or
" run make) and map that action to a key. Plugins can provide such actions by
" adding a feature of type feat_action.

let s:actions = config#GetG('config#actions', {'default' : [], 'set' : 1 })

" userinterface of core/autoload/tovl/ui/open_thing_at_cursor.vim
function! plugins#feature_types#action#PluginAction(p)
  let p = a:p
  let p['Tags'] = []
  let p['Info'] = "This feature type adds the mappings. Maybe you prefer map_with_esc_hack over this"
  " load after loading feature commands and mappings
  let p['loadingOrder'] = 50

  let p['defaults']['tags'] = ['feat_action'] 
  let p['defaults']['map_shift_fkeys_to_assign_action'] = "2-12"

  fun! p.Subst(s)
    return a:s
  endf
  " an action is { 'key' : ...; 'description' : ... ; 'action' : Function or string to be executed }
  " where key: short identifier of this action type (eg run-php-global or run-php-this-file)
  "       description: optional
  "       action: string or function returning string which will be mapped
  fun! p.RegisterAction(i)
    call tovl#list#AddUnique(s:actions, a:i)
  endf
  fun! p.UnregisterAction(i)
    call tovl#list#Remove(s:actions, a:i)
  endf
  let p['featureTypes'] = {
        \ 'feat_action' : {
        \ 'AddItem' : library#Function(p.RegisterAction, {'self' : p}),
        \ 'DelItem' : library#Function(p.UnregisterAction, {'self' : p}),
        \ }}

  " TODO add completion
  let p['feat_command'] = {
        \ 'map_action_id' : {
          \ 'name' : 'MapActionKey',
          \ 'attrs' : '-nargs=2',
          \ 'commad' : p.s.'.Map(<f-args>)',
        \ }}
  " you can use this function in your local vimrc files or such to add
  " mappings automatically. But you should prefer the command MapActionKey
  fun! p.Map(mapping, actionKey)
    try
      let action = filter(copy(s:actions), 'v:val["key"] == '.string(a:actionKey))[0]
    catch /.*/
      call self.Log(0, "exception couldn't find action by key ".a:actionKey)
    endtry
    " Maybe RegI of the plugin providing the action should be used?
    " Then the mapping would vanish if that plugin is deactivated.
    " I don't care. restarting vim is fast enough
    call self.RegI({
          \ 'featType' : "feat_mapping",
          \ 'lhs' : a:mapping,
          \ 'rhs' : '<esc>:'.library#Call(action['action']).'<cr>'
          \ })
  endfun

  fun! p.Assign(mapping)
    " ask user which action he wants to map
    let actions = map(copy(s:actions),'tovl#dict#CopyKeys(v:val, ["key","description"], 0)')
    call tovl#ui#filter_list#ListView({
          \ 'number' : 1,
          \ 'keys' : ['key','description','action'],
          \ 'selectByIdOrFilter' : 1,
          \ 'Continuation' : library#Function('call '. self.s .'.Map('.string(a:mapping).', ARGS[0]["key"])'),
          \ 'items' : actions
          \ })
  endf
  let child = {}
  fun! child.Load()
    let range_str = get(self.cfg,'map_shift_fkeys_to_assign_action','')
    if range_str =~ '\d\+-\d\+'
      for i in call(function('range'),split(range_str,'-'))
        call self.RegI({
              \ 'featType' : "feat_mapping",
              \ 'lhs' : '<s-f'.i.'>',
              \ 'rhs' : ':call '. self.s .'.Assign('.string('<f'.i.'>').')<cr>'
              \ })
      endfor
    else
      call self.Log(2, "couldn't parse map_shift_fkeys_to_assign_action value")
    endif
    call self.Parent_Load()
  endf
  return p.createChildClass(child)
endfunction
