" Both the FixPrefixesOfAutoloadFunctions command and mapping are experimental 
" For example it tries to fx' fun!  dict.Name() which is wrong
" However you can always just use undo..

function! plugins#filetype#cabal#cabal#PluginCabal(p)
  let p = a:p
  let p['Tags'] = ['filetype','cabal']
  let p['Info'] = "user completion, goto thing on cursor and fix function prefixes"

  let p['defaults']['tags_buftype'] = {'cabal' : ['cabal']}
  let p['defaults']['tags'] = ['cabal']

  " run this to fix prefixes of autoload functions (remember that you can use undo.. :-)
  let p['feat_mapping'] = {
    \ 'open_cabal_file' : {
      \ 'lhs' : '<m-e><m-c>',
      \ 'rhs' : ':call plugins#navigation#glob_open#FileByGlobCurrentDir("*.cabal",[])<cr>' }}

  " completion
  let p['feat_completion_func'] = {
    \ 'register_completion_func' : {
      \ 'description' : 'complete some cabal fields',
      \ 'completion_func' : library#Function('plugins#filetype#cabal#cabal#CompleteValues')}
    \ }
  return p
endfunction


" list is probably incomplete
let s:values = 
  \[ 'version: '
  \, 'license: '
  \, 'author: '
  \, 'homepage: '
  \, 'category: '
  \, 'build-depends: '
  \, 'synopsis: '
  \, 'exposed-modules: '
  \, 'other-modules: '
  \, 'hs-source-dirs: '
  \, 'src: '
  \, 'extra-lib-dirs: .: '
  \, 'extra-libraries: '
  \, 'include-dirs: '
  \, 'ghc-options: '
  \, 'extensions: '
  \, 'cpp-options: '
  \, 'bulidable: '
  \, 'build-type : '
  \]

fun! plugins#filetype#cabal#cabal#CompleteValues(findstart, base)
  if a:findstart
    let [bc,ac] = tovl#buffer#SplitCurrentLineAtCursor()
    return len(bc)-len(matchstr(bc,'\S*$'))
  else
    " find months matching with "a:base"
    let res = []
    for m in s:values
      if m =~ '^' . a:base
        call add(res, m)
      endif
    endfor
    return res
  endif
endfun

fun! plugins#filetype#cabal#cabal#OpenCabalFile()
endf
