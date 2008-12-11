" interface for haskell
function! plugins#language_support#haskell#PluginGhcSupport(p)
  let p = a:p
  let p['Tags'] = ['haskell','ghc','cabal']
  let p['Info'] = "this plugin provides an easy way to compile haskell programs"

  " run this to fix prefixes of autoload functions (remember that you can use undo.. :-)
  let p['commands']['Setup'] = {
    \ 'name' : 'SetupHaskellCompilationMapping',
    \ 'cmd' : 'call '.p.s.'.CabalSetup()',
    \ 'tags' : ['haskell']
    \ }

  let p['defaults']['lhs_compile'] = "<F2>"

  " if there is a .cabal file setup compilation mappings etc automatically
  let p['defaults']['autosetup'] = 1
  let p['defaults']['tags'] = ['haskell']
  let p['defaults']['tags_buftype'] = {'haskell' : 'haskell'}
  let p['defaults']['known_ghcs'] = ["ghc"]

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
         \ 'rhs' : '<esc>:call '. self.s .'.NewSetupProcess().Run()<cr>',
         \ 'tags' : ['haskell']
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
    " later I'll check wether this is an HAppS server project and restart the
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
      let cabalBuildDir = map(
             \ split(glob("*/setup-config"),"\n")
           \ , 'fnamemodify(v:val, ":h")')
      let self.cabalBuildDir = tovl#ui#choice#LetUserSelectIfThereIsAChoice("Which cabal setup to use ?", cabalBuildDir)
    endif
  endfunction

  fun! child.Unload()
    call self.Parent_Unload()
  endf
  return p.createChildClass(child)
endfunction