" interface for haskell
" also see PluginCabal
function! plugins#language_support#haskell#PluginGhcSupport(p)
  let p = a:p
  let p['Tags'] = ['haskell','ghc','cabal']
  let p['Info'] = "this plugin provides an easy way to compile haskell programs"

  " run this to fix prefixes of autoload functions (remember that you can use undo.. :-)
  let p['feat_command'] = { 'Setup' : {
    \ 'name' : 'SetupHaskellCompilationMapping',
    \ 'cmd' : 'call '.p.s.'.CabalSetup()',
    \ }}

  let p['defaults']['lhs_compile'] = "<F2>"

  " if there is a .cabal file setup compilation mappings etc automatically
  let p['defaults']['autosetup'] = 1
  let p['defaults']['tags'] = ['haskell']
  let p['defaults']['tags_filetype'] = {'haskell' : 'haskell'}
  let p['defaults']['known_ghcs'] = ["ghc"]

  fun! p.RunPHPActionString()
    return 'wa <bar>'
          \ . 'call tovl#runtaskinbackground#Run('.string({'cmd': [self.cfg.php_executable, expand('%')],
                                                          \ 'ef' : 'plugins#tovl#errorformats#PluginErrorFormats#php', 'onFinishCallbacks' : ['cope']}).')'
  endf
  let p['feat_action'] = {
        \ 'ghc_compile_this_file' : {
        \   'key': 'ghc_compile_this_file',
        \   'description': "removes the file extension to get the executable name and executes it",
        \   'action' : library#Function('return '. p.s. '.CompileAction()')
        \ },
        \ 'ghc_run_this_as_executable' : {
        \   'key': 'ghc_run_this_as_executable',
        \   'description': "Compiles this file using ghc. If more than one ghc are known you'll have to specify one.\n".
                         \ "If the file contains a -- packages:base,filepath  list this the known packages will be limited to this one",
        \   'action' : library#Function('return "!".expand("%:p:r")')
        \ }}

  fun! p.CompileAction()
    return 'call '. self.s .'.CompileFileWithGhc('.string(expand('%:p')).', '.string(self.ChooseGhc()).',0)'
  endf

  fun! p.CompileFileWithGhc(file, ghc, profiling)
    " first write all buffers
    wa
    let cmd = [a:ghc,'--make']
    let regex = '^--\s\+packages\s\+:\s*\zs.\{-}\s*$'
    let lines = filter(readfile(a:file), 'v:val =~ '.string(regex))
    if !empty(lines)
      call extend(cmd, ['--hide-all-packages']
        \ + tovl#list#Concat(map( split(matchstr(regex, lines[0]),'\s*,\s*')
                                \ '["--package", v:val]')))
    endif
    if a:profiling
      call extend(cmd, ['-prof','-auto-all'])
    endif
    call extend(cmd, ['-o', fnamemodify(a:file, ':r')])
    call add(cmd, a:file)
    " cope to also show warnings and all output..
    call tovl#runtaskinbackground#Run({'cmd': cmd, 'ef' : 'plugins#tovl#errorformats#PluginErrorFormats#ghc', 'onFinishCallbacks' : ['cope']})
  endf

  fun! p.ChooseGhc()
    let ghcs = self.cfg.known_ghcs
    if empty(ghcs)
      throw "no ghc known? Please set ". p.pluginName ."#known_ghcs (list of known ghc paths) in TOVLConfig"
    else
      return tovl#ui#choice#LetUserSelectIfThereIsAChoice('ghc: ', ghcs)
    endif
  endf

  let child = {}
  fun! child.Load()
    if self.cfg.autosetup
      call self.CabalSetup()
    endif
    call self.Parent_Load() 
  endfunction

  fun! child.CabalSetup()
    let self.cabal_file = ''
    let self.cabalBuildDir = ''
    call self.DefineCabalFile()
    if self.cabal_file == ''
      call self.Log(1,"no cabal file found!")
      return
    endif
    call self.DefineBuildDir()
    if self.cabalBuildDir != ''
      " assuming there is a ./setup executable.. I'm not using runhaskell
      call self.RegI({
         \ 'lhs' : self.cfg.lhs_compile,
         \ 'rhs' : '<esc>:wa<bar>call '. self.s .'.NewSetupProcess().Run()<cr>',
         \ 'featType' : 'feat_mapping'
         \ })
    else
      call self.Log(1,"cabal file found but no dist directory. You have to configure cabal first!")
      return 
    endif
  endf

  fun! child.NewSetupProcess()
    return tovl#runtaskinbackground#NewProcess( 
     \ { 'cmd': ["./setup",'build',"--builddir=".self.cabalBuildDir]
     \ , 'ef' : 'plugins#tovl#errorformats#PluginErrorFormats#ghc'
     \ , 'onFinishCallbacks' : [library#Function(self.CompilationFinishedCallback,{'self' : self})]
     \ })
  endf

  fun! child.CompilationFinishedCallback(p)
    " later I'll check wether this is an HappS server project and restart the
    " application ..
  endf

  function! child.DefineCabalFile()
    let cabal_files = split(glob('*.cabal'),"\n")
    if len(cabal_files) > 0
      let self.cabal_file = tovl#ui#choice#LetUserSelectIfThereIsAChoice("from which cabal file may I take the executable names? ", cabal_files)
    endif
  endfunction

  function! child.DefineBuildDir()
    if self.cabal_file != ''
      let cabalBuildDirs = map(
             \ split(glob("*/setup-config"),"\n"),
             \ 'fnamemodify(v:val, ":r")')
      if len(cabalBuildDirs) > 0
        let self.cabalBuildDir = tovl#ui#choice#LetUserSelectIfThereIsAChoice(
              \ "Which cabal setup to use ?", cabalBuildDirs)
      endif
    endif
  endfunction

  fun! child.Unload()
    call self.Parent_Unload()
  endf
  return p.createChildClass(child)
endfunction
