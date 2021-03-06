" Both the FixPrefixesOfAutoloadFunctions command and mapping are experimental 
" For example it tries to fx' fun!  dict.Name() which is wrong
" However you can always just use undo..

function! plugins#filetype#vim#vl_repo#PluginVL_RepoStuff(p)
  let p = a:p
  let p['Tags'] = ['filetype','vimscript']
  let p['Info'] = "user completion, goto thing on cursor and fix function prefixes"

  let p['defaults']['tags_buftype'] = {'vim' : ['vim']}
  let p['defaults']['tags'] = ['vim']
  " run this to fix prefixes of autoload functions (remember that you can use undo.. :-)
  let p['feat_mapping'] = {
    \ 'fix_function_prefixes' : {
      \ 'lhs' : '<m-f><m-p>',
      \ 'rhs' : ':call tovl#ft#vimscript#vimfile#FixPrefixesOfAutoloadFunctions()<cr>' }}
  let p['feat_command'] = {
    \ 'fix_function_prefixes' : {
      \ 'name' : 'FixPrefixesOfAutoloadFunctions',
      \ 'attrs' : '-nargs=0',
      \ 'cmd' : ':call tovl#ft#vimscript#vimfile#FixPrefixesOfAutoloadFunctions()<cr>' }}

  " put cursor on autolad function and press gf to jump to the file or to create
  " a new file.
  let p['feat_GotoThingAtCursor'] = 
    \ { 'goto_thing_handler' : {
    \ 'buffer' : 1
    \ ,'f' : library#Function('tovl#ft#vimscript#vimfile#GetFuncLocation', {'args' : [1]})}}

  " completion
  let p['feat_completion_func'] = {
    \ 'register_completion_func' : {
      \ 'description' : 'vim funtion completion based on ScanAndCache scanned .vim files found in &runtimepath',
      \ 'completion_func' : library#Function('tovl#ft#vimscript#vimfile#CompleteFunction')}
    \ }

  " command
  let p['autocommands']['fix_prefixes_cmd'] = {
      \ 'events' : 'FileType',
      \ 'pattern' : 'vim',
      \ 'cmd' : "command! -buffer -nargs=0 FixPrefixesOfAutoloadFunctions :call tovl#ft#vimscript#vimfile#FixPrefixesOfAutoloadFunctions()<cr>"
    \ }

  return p
endfunction
