function! plugins#filetype#vim#vl_repo#PluginVL_RepoStuff(p)
  let p = a:p
  let p['Tags'] = ['filetype','vimscript']
  let p['Info'] = "user completion, goto thing on cursor and fix function prefixes"

  " run this to fix prefixes of autoload functions (remember that you can use undo.. :-)
  let p['mappings']['fix_function_prefixes'] = {
    \ 'ft' : 'vim', 'm':'n', 'lhs' : '<m-f><m-p>',
    \ 'rhs' : ':call tovl#ft#vimscript#vimfile#FixPrefixesOfAutoloadFunctions()<cr>' }

  " put cursor on autolad function and press gf to jump to the file or to create
  " a new file.
  let p['autocommands']['on_thing_handler'] = {
    \ 'events' : 'FileType',
    \ 'pattern' : 'vim',
    \ 'cmd' : "call tovl#ui#open_thing_at_cursor#AddOnThingHandler("
            \ ."library#Function('tovl#ft#vimscript#vimfile#GetFuncLocation', {'args' : [1]}))" }

  " completion
  let p['autocommands']['register_completion_func'] = {
    \ 'events' : 'FileType',
    \ 'pattern' : 'vim',
    \ 'cmd' : "call tovl#ui#multiple_completions#RegisterBufferCompletionFunc({"
          \ ."'description': 'use camle case matching to complete functions BGP -> config#GetByPath',"
          \ ."'func': library#Function('tovl#ft#vimscript#vimfile#CompleteFunction')})"
          \ }

  " command
  let p['autocommands']['fix_prefixes_cmd'] = {
    \ 'events' : 'FileType',
    \ 'pattern' : 'vim',
    \ 'cmd' : "command! -buffer -nargs=0 FixPrefixesOfAutoloadFunctions :call tovl#ft#vimscript#vimfile#FixPrefixesOfAutoloadFunctions()<cr>"
          \ }
  return p
endfunction
