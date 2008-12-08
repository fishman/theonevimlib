" userinterface of tovl/ui/multiple_completions.vim
function! plugins#navigation#glob_open#PluginGlobOpen(p)
  let p = a:p
  let p['Tags'] = ['navigation', 'glob','open','edit']
  let p['Info'] = "open a file by glob pattern. Don't use it in big directories."
  let p['mappings']['glob_open'] = {
    \ 'ft' : '', 'm':'n', 'lhs' : '<m-g><m-o>',
    \ 'rhs' : ":exec 'e '.".p.s.".FileByGlobCurrentDir(input('glob open '))<cr>" }
  let p['defaults']['exclude'] = ['v:val !~ '.string('\.o$\|\.hi$\|\.svn$\|.git$\|_darcs$$\|.darcs$\|.hg'),'!isdirectory(v:val)']
  let p['defaults']['listMax'] = 20

  function! p.FileByGlobCurrentDir(glob, ...)
    exec library#GetOptionalArg('caption', string('Choose a file'))
    let files = split(glob('**/*'.a:glob.'*'),"\n")

    for nom in config#Get(self.pluginName.'#exclude')
      echo nom
      call filter(files,nom)
    endfor

    if len(files) > self.cfg.listMax
      echoe "more than ".self.cfg.listMax" files - would be too slow. Open the file in another way"
    else
      call filter(files, 'v:val !~ "_darcs" ')
      return tovl#ui#choice#LetUserSelectIfThereIsAChoice(caption, files)
    endif
  endfunction

  return p
endfunction

