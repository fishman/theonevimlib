" run this to fix prefixes of autoload functions (remember that you can use undo.. :-)
command! -buffer -nargs=0 FixPrefixesOfAutoloadFunctions :call tovl#ft#vimscript#vimfile#FixPrefixesOfAutoloadFunctions()<cr>

" put cursor on autolad function and press gf to jump to the file or to create
" a new file.
call tovl#ui#open_thing_at_cursor#AddOnThingHandler(
  \ library#Function("tovl#ft#vimscript#vimfile#GetFuncLocation", {'args' : [1]}))

call tovl#ui#multiple_completions#RegisterBufferCompletionFunc({
      \ 'description': "use camle case matching to complete functions BGP -> config#GetByPath",
      \ 'func': library#Function('tovl#ft#vimscript#vimfile#CompleteFunction')
      \ })
