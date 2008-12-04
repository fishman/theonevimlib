" link-doc: ./exmple.txt
" a basic plugin should define the following keys:

" load:   this code will run by exec to setup plugin stuff.
" unload: this code should do the opposite. [optional]
" info:   some short text about whot the plugin is supposed to do
" AddDefaultConfigOptions: Use this to add default configuration options
"                          be careful to not override user changes!
"                          Will be called before the main configuration is
"                          shown for all activated plugins

function! plugins#example#PluginSimpleCommandExample()
  return {
  \ 'load': 'call plugins#example#Load()',
  \ 'unload': 'call plugins#example#Unload()',
  \ 'info': string('basic plugin demo'),
  \ 'tags' : ['example','demo']
  \ 'AddDefaultConfigOptions' : "call plugins#example#AddDefaultConfigOptions()"
  \ }
endfunction

function! plugins#example#Load()
  call config#AddToList('config#onChange', library#Function('plugins#example#OnChange'))

  echom "loading example plugin stub"
  let g:example_loaded = 1
  let d = config#Get('example', {'default' : {}})

  " make a copy of the settings to get to know wether something has changed
  call config#SetG('plugins#example#opts', deepcopy(d))

  let cmdName = get(d,'commandName','ExamplePluginHW')

  " remember command name so that we can remove it again..
  call config#SetG('plugins#example#cmdName',cmdName)

  exec 'command! '.cmdName.' '.get(d,'command','echo "unset"')
endfunction

function! plugins#example#Unload()
  echom "unloading example plugin stub"
  let g:example_loaded = 0
  try
    exec 'delc '.config#GetG('plugins#example#cmdName')
  catch /.*/
  endtry
endfunction

function! plugins#example#AddDefaultConfigOptions()
  let g:g = "ward"
  let d = config#Get('example', {'default' : {}, 'set' :1})
  if !has_key(d, 'commandName')
    call config#Set('example#commandName',"ExamplePluginHW")
  endif
  if !has_key(d, 'command')
    call config#Set('example#command', "echo ".string("hello world to you from example plugin"))
  endif
endfunction

function! plugins#example#OnChange()
  if config#GetG('plugins#example#opts') != config#Get('example', {})
    " options have changed, reload
    call plugins#example#Unload()
    call plugins#example#Load()
  endif
endfunction
