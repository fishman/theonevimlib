" the implementation can be found in core/autoload/tovl/runtaskinbackground.vim

function! plugins#tovl#runtaskinbackground#PluginRunTaskInBackground(p)
  let p = a:p
  let p['Tags'] = ['templates','vimscript']
  let p['Info'] = "This is the configuration interface for  autoload/tovl/runtaskinbackground.vim"

  " You can do fancy things here such as setting different colorschemes etc
  let p['defaults']['process_obj_decorator_fun'] = library#Function('tovl#runtaskinbackground#DefaultDecorator')
  let p['defaults']['color_scheme_when_a_bg_process_is_running'] = ''

  let p['defaults']['tags'] = ['run_task_in_background']

  let p['feat_command'] = {
      \ 'run_command_in_background_qf' : {
        \ 'name' : 'RunBGQF',
        \ 'attrs' : '-nargs=1',
        \ 'cmd' : 'call '.p.s.'.RunBGQF(<f-args>)'
      \ }}
  fun! p.RunBGQF(dict)
    let n = NewPro
  endf
  
  let p['defaults']['run_handlers'] = [
    \ library#Function('tovl#runtaskinbackground#RunHandlerPython'),
    \ library#Function('tovl#runtaskinbackground#RunHandlerSh'),
    \ library#Function('tovl#runtaskinbackground#RunHandlerSystem')
    \ ]
  return p
endfunction
