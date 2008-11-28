" link-doc: ./exmple.txt
" a basic plugin should define the following keys:

" load:   this code will run by exec to setup plugin stuff.
" unload: this code should do the opposite. [optional]
" info:   some short text about whot the plugin is supposed to do

function #s:Info()
  return {
  \ 'laod': 'call vl#lib#vimscript#scriptsettings#Load()',
  \ 'info': string('basic plugin demo')
  \ }
endfunction

function! plugins#example#Load()
endfunction
