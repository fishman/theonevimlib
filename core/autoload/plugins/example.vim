" link-doc: ./exmple.txt
" a basic plugin should define the following keys:

" Load:   this code will run by exec to setup plugin stuff.
" Unload: this code should do the opposite. [optional]
" Info:   some short text about whot the plugin is supposed to do
" Tags:
" AddDefaultConfigOptions: Use this to add default configuration options
"                          be careful to not override user changes!
"                          Will be called before the main configuration is
"                          shown for all activated plugins. Also see defaults
"                          below
" defaults:   you can set this to a dict { "opt#subkey": 0 } instead
"             AddDefaultConfigOptions will be set to a default implementation.

let s:file = expand('<sfile>')

" This example is the most simple one
" just define a user interface within an external file
function! plugins#example#PluginExampleCmd()
  let d = {
        \ 'Tags': ['example','demo'],
        \ 'Info': string('basic plugin demo only exposing some mappings'),
        \ 'cmd' : library#ReadLazy(fnamemodify(s:file,":p:r").'_userinterface.vim',{'join':1})
        \ }
  " key filetype:"vim" will make the command only be executed if filetype vim is set

  return tovl#plugin_management#DefaultPluginDictCmd(d)
endfunction

function! plugins#example#PluginExample()
  let d = {
        \ 'Tags': ['example','demo'],
        \ 'Info': string('basic plugin demo')
        \ }

  function! d.Load()
    call config#AddToList('config#onChange', library#Function(self['OnChange'],{'self' : self}))

    let g:example_loaded = 1
    let d = config#Get(self.pluginName, {'default' : {}})

    " make a copy of the settings to get to know wether something has changed
    let self['opts'] = deepcopy(d)

    let cmdName = get(d,'commandName','ExamplePluginHW')

    " remember command name so that we can remove it again..
    let self['cmdName'] = cmdName

    exec 'command! '.cmdName.' '.get(d,'command','echo "unset"')
  endfunction

  function! d.Unload()
    echom "unloading example plugin stub"
    let g:example_loaded = 0
    try
      exec 'delc '.self['cmdName']
    catch /.*/
    endtry
  endfunction

  function! d.AddDefaultConfigOptions(dict)
    let d = config#GetByPath(a:dict,self.pluginName, {'default' : {}, 'set' :1})
    if !has_key(d, 'commandName')
      call config#SetByPath(a:dict, self.pluginName.'#commandName',"ExamplePluginHW")
    endif
    if !has_key(d, 'command')
      call config#SetByPath(a:dict, self.pluginName.'#command', "echo ".string("hello world to you from example plugin"))
    endif
  endfunction

  function! d.OnChange()
    if self['opts'] != config#Get(self.pluginName, {})
      " options have changed, reload
      call self.Unload()
      call self.Load()
    endif
  endfunction

  return d
endfunction
