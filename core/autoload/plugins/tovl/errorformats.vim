" configuration interface for autoload/tovl/error_format.vim
"
" I never remember how to quote errorformats. That's why I've written this
" plugin

function! plugins#tovl#errorformats#PluginErrorFormats(p)
  let p = a:p
  let p['Tags'] = ['errorformats','quickfix','backgrounding']
  let p['Info'] = "This scripts provides some errorformats"

  let p['defaults']['tags'] = ['error_formats']

  let p['feat_command'] = {
      \ 'set_errorformat' : {
        \ 'name' : 'SetErrorFormat',
        \ 'attrs' : '-nargs=1 -complete=customlist,plugins#tovl#errorformats#CompleteEFM',
        \ 'cmd' : ':call tovl#errorformat#SetErrorFormat("plugins#tovl#errorformats#PluginErrorFormats#".<f-args>)'
      \ }
    \ }

  let p['defaults'] = {}
  let ef = p['defaults']
  " the result of this list will be read by a fitting handler
  " (template_handlers).
  let ef['python'] = '%A  File "%f", line %l, %m' 
  let ef['nix'] =  "%m, at `%f':%l:%c"
                \ . "%m at `%f', line %l:\n"
                \ . "\nerror: %m, in `%f'\n" 
  let ef['xmllint'] =  '%f:%l: %m'
  let ef['gcc'] =  "%f:%l: %trror: %m\n"
              \ . "%f:%l: F%thler: %m"

  let ef['nix'] = "%m, at `%f':%l:%c\n"
              \ . "%m at `%f', line %l:\n"
              \ . "error: %m, in `%f'"



" - Ignore the obvious.
" - Don't include the 'a-okay' message.  let ef['perl'] = 
" - Most errors...
" - As above, including ', near ...'
" -   ... Which can be multi-line.     " %-G%.%#had\ compilation\ errors.,  
  let ef['perl'] = "%-G%.%#syntax OK\n"
              \ . "%m at %f line %l.\n"
              \ . "%+A%.%# at %f line %l\\,%.%#\n"
              \ . "%+C%.%#"
  " TODO: tidy this up!
  let ef['php'] = "%m %f:%l\n"
              \ . "%f:%l\n"
              \ . "%m %f:%l\n"
              \ . "%E<b>Parse error</b>: %m in <b>%f</b> on line <b>%l</b><br />\n"
              \ . "%EFatal error: %m in %f on line %l\n"
              \ . "%EPHP Fatal error: %m in %f on line %l\n"
              \ . "%EPHP Parse error: %m in %f on line %l\n"
              \ . "%EFatal error: %m in %f:%l\n"
              \ . "%W<b>Notice</b>: %m in <b>%f</b> on line <b>%l</b><br />\n"
              \ . "%EParse error: %m in %f on line %l\n"
              \ . "%E#0 %f(%l): %m\n"
              \ . "%E#1 %f(%l): %m\n"
              \ . "%E#2 %f(%l): %m\n"
              \ . "%E#3 %f(%l): %m\n"
              \ . "%E#4 %f(%l): %m\n"
              \ . "%E#5 %f(%l): %m\n"
              \ . "%E#6 %f(%l): %m\n"
              \ . "%E#7 %f(%l): %m\n"
              \ . "%E#8 %f(%l): %m\n"
              \ . "%E#9 %f(%l): %m\n"
              \ . "%E#10 %f(%l): %m\n"
              \ . "%E#11 %f(%l): %m\n"
              \ . "%E#12 %f(%l): %m\n"
              \ . "%E#13 %f(%l): %m\n"
              \ . "%E#14 %f(%l): %m\n"
              \ . "%E#15 %f(%l): %m\n"
              \ . "%E#16 %f(%l): %m\n"
              \ . "%E#17 %f(%l): %m\n"
              \ . "%E#18 %f(%l): %m\n"
              \ . "%E#19 %f(%l): %m\n"
              \ . "%E#20 %f(%l): %m\n"
              \ . "%E#21 %f(%l): %m\n"
              \ . "%E#22 %f(%l): %m\n"
              \ . "%E#23 %f(%l): %m\n"
              \ . "%E#24 %f(%l): %m\n"
              \ . "%E#25 %f(%l): %m\n"
              \ . "%E#26 %f(%l): %m\n"
              \ . "%WNotice: %m in %f</b> on line %l\n"
              \ . "%m. %f:%l\n"
              \ . "%f:%l"
  let ef['ghc'] = 
              \ "%f:%l:%c:%m\n"
              \ ."%E%f:%l:%c:\n"
              \ ."%m:%f:%l:%c:"
  let ef['js_spidermonkey'] =
              \    "%E%f:%l: %m\n"
              \  . "%-C:%l: %s\n"
              \  . "%Z%s:%p^\n"
  let ef['mxmlc'] = "%f(%l): col: %c Error:%m"
  " dummy, shows all lines. Hopefully no line ever contains that pattern..
  let ef['none'] = "dummy_dummy_dummy_line_1034985"
  " remember to use grep -n !
  let ef['grep'] = "%f:%l:%m"
  return p
endfunction

fun! plugins#tovl#errorformats#CompleteEFM(A,L,P)
    return filter(keys(config#Get('plugins#tovl#errorformats#PluginErrorFormats', { 'default' : {}}))
      \ , 'v:val =~ '.string(a:A))
endf
