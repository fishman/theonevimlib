" link-doc: ./exmple.txt
" a basic plugin should define the following keys:

" load:   this code will run by exec to setup plugin stuff.
" unload: this code should do the opposite. [optional]
" info:   some short text about whot the plugin is supposed to do
" AddDefaultConfigOptions: Use this to add default configuration options
"                          be careful to not override user changes!
"                          Will be called before the main configuration is
"                          shown for all activated plugins

function! plugins#example#PluginExample()
  let d = {
        \ 'tags': library#Function("plugins#example#AddDefaultConfigOptions"),
        \ 'info': string('basic plugin demo')
        \ }

  function! d.Load()
    call config#AddToList('config.onChange', library#Function(self['OnChange'],{'self' : self}))

    echom "loading example plugin stub"
    let g:example_loaded = 1
    let d = config#Get('example', {'default' : {}})

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
    let d = config#GetByPath(a:dict,'example', {'default' : {}, 'set' :1})
    if !has_key(d, 'commandName')
      call config#SetByPath(a:dict, 'example.commandName',"ExamplePluginHW")
    endif
    if !has_key(d, 'command')
      call config#SetByPath(a:dict, 'example.command', "echo ".string("hello world to you from example plugin"))
    endif
  endfunction

  function! d.OnChange()
    if self['opts'] != config#Get('example', {})
      " options have changed, reload
      call self.Unload()
      call self.Load()
    endif
  endfunction

  return d
endfunction
