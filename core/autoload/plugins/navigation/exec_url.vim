" this plugin provides a way to view tovl_exec://prog?arg?arg files
" it simply runs the command and shows the output.
" The delimiter ? has been chosen because it is unlikely to occur in filenames
" but easy to remember
"
" Eg it is used by the git viewer to easily browse git repositories..

function! plugins#navigation#exec_url#PluginExecUrl(p)
  let p = a:p
  let p['Tags'] = []
  let p['Info'] = "tovl_exec://prog#arg#arg views"
  let p['defaults']['configDummy'] = "make this plugin load cause it hasn't any options"

  let child = {}
  fun! child.Load()
    " TODO use real command feature here 
    call self.Parent_Load()
    call self.Au({'events' : 'BufReadCmd', 'pattern' : 'tovl_exec://*',
      \ 'cmd' : 'call '. self.s .'.ExecRead()'})
  endf
  fun! child.ExecRead()
    let g:g=9
    " FIXME, doesn't work yet!
    " TODO allow escaping of ?
    let cmd = split(matchstr(expand('%'),'tovl_exec://\zs.*'), '?')
    try
      let lines = split(tovl#runtaskinbackground#System(cmd),"\n")
      " check wether we do have ff=dos !
      if !empty(lines)
        let copy = []
        for l in copy
          if l[-1] == '\r'
            call add(copy, l[:-1])
          else
            break
          endif
        endfor
        " all have \r ?
        if len(copy) == len(lines)
          let lines = copy
          set ff=dos
        endif
      endif
      call append(0, lines)
    catch /.*/
      call append(0, split(v:exception,"\n"))
    endtry
  endf
  return p.createChildClass(child)
endfunction
