" interface for running grep in background.. (TODO)
" This is only a draft


function! plugins#background_processes#grep#PluginBackgroundGrep(p)
  let p = a:p
  let p['Tags'] = ['syntax','php','javascript','xml']
  let p['Info'] = "experimental proof of concept grep interface. Must be enhanced"

  let p['mappings']['background_grep_dialog'] = {
    \ 'ft' : '', 'm':'n', 'lhs' : '<m-g><m-r>',
    \ 'rhs' : ':call '.p.s.'.Dialog()<cr>'
    \ }
  let child = {}
  fun! child.Dialog()
    let word = input('string to find -R . :')
    if word == '' | echo "aborted" | return | endif

   call tovl#runtaskinbackground#NewProcess(
         \ { 'name' : 'bg_grep', 'cmd': ["grep","-R",'-n',word,'.'], 'ef' : 'plugins#tovl#errorformats#PluginErrorFormats#grep' }).Run()
  endf
  fun! child.Load()
    call self.LogExec(1, 'command: ','command -nargs=0 BGGrepR call '.self.s.'.Dialog()')
    call self.Parent_Load()
  endf
  fun! child.Unload()
    delc BGGrepR
    call self.Parent_Unload()
  endf
  return p.createChildClass(child)
endfunction
