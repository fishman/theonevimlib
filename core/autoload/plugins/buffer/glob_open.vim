" userinterface of tovl/ui/multiple_completions.vim
function! plugins#buffer#glob_open#PluginGlobOpen()
  let d = {
        \ 'Tags': ['navigation', 'glob','open','edit'],
        \ 'Info': "open a file by glob pattern. Don't use it in big directories.",
        \ 'cmd' : "noremap <m-g><m-o> :exec 'e 'plugins#buffer#glob_open#FileByGlobCurrentDir(input('glob open '))<cr>",
        \ 'defaults' : {
              \ 'exclude' : ['v:val !~ '.string('\.o$\|\.hi$\|\.svn$\|.git$\|_darcs$$\|.darcs$\|.hg'),'!isdirectory(v:val)'],
              \ 'listMax' : 20
              \ }
        \ }
  return tovl#plugin_management#DefaultPluginDictCmd(d)
endfunction

function! plugins#buffer#glob_open#FileByGlobCurrentDir(glob, ...)
  exec library#GetOptionalArg('caption', string('Choose a file'))
  let files = split(glob('**/*'.a:glob.'*'),"\n")
  let pn = 'plugins#buffer#glob_open#PluginGlobOpen'


  for nom in config#Get(pn.'#exclude')
    echo nom
    call filter(files,nom)
  endfor

  " TODO! 
  if len(files) > config#Get(pn.'#listMax')
    echoe "more than 20 files - would be to slow. Open the file in another way"
  else
    call filter(files, 'v:val !~ "_darcs" ')
    return tovl#ui#choice#LetUserSelectIfThereIsAChoice(caption, files)
  endif
endfunction
