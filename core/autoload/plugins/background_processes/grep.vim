" interface for running grep in background.. (TODO)
" This is only a draft


function! plugins#background_processes#grep#PluginBackgroundGrep(p)
  let p = a:p
  let p['Tags'] = ['syntax','php','javascript','xml']
  let p['Info'] = "experimental proof of concept grep interface. Must be enhanced"

  let p['defaults']['tags'] = ['background_grep']

  let p['feat_mapping'] = {
    \ 'background_grep_dialog' : {
      \ 'lhs' : '<m-g><m-r>',
      \ 'rhs' : ':call '.p.s.'.Dialog()<cr>'
      \ }}
  let child = {}
  fun! child.Dialog()
    let word = input('string to find -R . :')
    if word == '' | echo "aborted" | return | endif

   call tovl#runtaskinbackground#NewProcess(
         \ { 'name' : 'bg_grep', 'cmd': ["grep","-R",'-n',word,getcwd()], 'ef' : 'plugins#tovl#errorformats#PluginErrorFormats#grep' }).Run()
  endf
  fun! child.Load()
    " TODO use real command feature here 
    call self.LogExec(1, 'command: ','command -nargs=0 BGGrepR call '.self.s.'.Dialog()')
    call self.Parent_Load()
  endf
  fun! child.Unload()
    delc BGGrepR
    call self.Parent_Unload()
  endf
  return p.createChildClass(child)
endfunction

function! plugins#background_processes#grep#PluginGNUIdUtils(p)
  let p = a:p
  let p['Tags'] = []
  let p['Info'] = "Minimal support for ID utilities. An ID database is a binary file containing a list of file names, a list of tokens, and a sparse matrix indicating which tokens appear in which files."

  let p['defaults']['tags'] = ['id_utilities']

  " you may want to pass your own mapping file or such.. 
  let p['defaults']['mkid_command'] = library#Function('return ["mkid"]')

  let p['feat_mapping'] = {
    \ 'gun_id_utilities_lid_dialog' : {
      \ 'lhs' : '<m-l><m-i><m-d>',
      \ 'rhs' : ':call '.p.s.'.Dialog()<cr>'
      \ },
    \ 'gun_id_utilities_lid_mkid' : {
      \ 'lhs' : '<m-m><m-i><m-d>',
      \ 'rhs' : ':call '.p.s.'.RecreateDB()<cr>'
      \ }
    \ }
  let child = {}

  fun! child.RecreateDB()
    call tovl#runtaskinbackground#NewProcess(
         \ { 'name' : 'bg_mid', 'cmd': library#Call(self.cfg.mkid_command), 'ef' : "plugins#tovl#errorformats#PluginErrorFormats#none"}).Run()
  endf
  fun! child.Dialog()
    let word = input('lid word to find (lid -R grep -r word, -r = regex, ^foo$ matches "\<foo\>") :')
    if word == '' | echo "aborted" | return | endif
    call tovl#runtaskinbackground#NewProcess(
         \ { 'name' : 'bg_lid', 'cmd': ["lid","-R","grep","-r",word], 'ef' : 'plugins#tovl#errorformats#PluginErrorFormats#grep' }).Run()
  endf
  fun! child.Load()
    " TODO use real command feature here 
    call self.LogExec(1, 'command: ','command -nargs=0 LID call '.self.s.'.Dialog()')
    call self.Parent_Load()
  endf
  fun! child.Unload()
    delc BGGrepR
    call self.Parent_Unload()
  endf
  return p.createChildClass(child)
endfunction
