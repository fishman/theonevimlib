" the implementation can be found in core/autoload/tovl/runtaskinbackground.vim

function! plugins#tovl#runtaskinbackground#PluginRunTaskInBackground(p)
  let p = a:p
  let p['Tags'] = ['templates','vimscript']
  let p['Info'] = "This is the configuration interface for  autoload/tovl/runtaskinbackground.vim"

  " You can do fancy things here such as setting different colorschemes etc
  let p['defaults']['process_obj_decorator_fun'] = library#Function('tovl#runtaskinbackground#DefaultDecorator')
  
  let p['defaults']['run_handlers'] = [
    \ library#Function('tovl#runtaskinbackground#RunHandlerPython'),
    \ library#Function('tovl#runtaskinbackground#RunHandlerSh'),
    \ library#Function('tovl#runtaskinbackground#RunHandlerSystem')
    \ ]
  return p
endfunction
