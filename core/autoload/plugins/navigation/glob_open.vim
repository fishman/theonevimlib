" userinterface of tovl/ui/multiple_completions.vim
function! plugins#navigation#glob_open#PluginGlobOpen(p)
  let p = a:p
  let p['Tags'] = ['navigation', 'glob','open','edit']
  let p['Info'] = "open a file by glob pattern. Don't use it in big directories."

  let p['defaults']['tags'] = ['glob_open']
  let p['feat_mapping'] = {
        \ 'glob_open' : {
        \ 'lhs' : '<m-g><m-o>',
        \ 'rhs' : ":call ".p.s.".FileByGlobCurrentDir(input('glob open '))<cr>" }
      \ }
  let p['defaults']['exclude'] = ['v:val !~ '.string('\.o$\|\.hi$\|\.svn$\|.git$\|_darcs$$\|.darcs$\|.hg'),'!isdirectory(v:val)']

  function! p.FileByGlobCurrentDir(glob, ...)
    exec library#GetOptionalArg('caption', string('Choose a file'))
    let files = split(glob('**/*'.a:glob.'*'),"\n")
    for nom in config#Get(self.pluginName.'#exclude')
      call filter(files,nom)
    endfor
    if len(files) > 1000
      echoe "more than ".2000." files - would be too slow. Open the file in another way"
    else
      if empty(files)
	echoe "no file found"
      elseif len(files) == 1
	exec 'e '.files[0]
      else
	let g:abc=7
	call tovl#ui#filter_list#ListView({
	      \ 'number' : 1,
	      \ 'selectByIdOrFilter' : 1,
	      \ 'Continuation' : library#Function('exec "e ".ARGS[0]'),
	      \ 'items' : files,
	      \ })
      endif
    endif
  endfunction

  return p
endfunction

