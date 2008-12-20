" @cmd: the command to be run such as ["make","-j","2","foo"]
" opts: dict with optional keys
"    onStart : list of cmds [1]
"    onFinish : list of cmds [1]
"    stdin : text
"    exitCode: the expected exit code (default 0)
"    ef : id of errorformat. If set and the command has finished the output
"         will be loaded into quickfix
"         See :h tovl-error-formats
"    fg : don't try running in background
"
" [1]:
" OPTS is the dict containing all information:

let s:next_process_id = 0
let s:status = config#GetG('tovl#running_background_processes', {'set' :1, 'default' : {}})

fun! s:Log(...)
  call library#Call(library#Function('tovl#log#Log'), ["runtaskinbackground"] + a:000)
endf

" usage:
" let p = tovl#runtaskinbackground#NewProcess(
"   \ {'name' : 'compilation', 'cmd': ["/bin/sh","-c",'sleep 10; echo done']})
" call p.Run()
fun! tovl#runtaskinbackground#NewProcess(p)
  let process = tovl#obj#NewObject('process')
  let process['id'] = s:next_process_id
  let process['fg'] = 0
  let process['tempfile'] = tempname()
  let s:next_process_id = s:next_process_id + 1
  let process['expectedExitCode'] = 0
  fun! process.PreStart()
    echo "starting process ".self.id
  endf
  " override OnFinish instead
  fun! process.Finished(exitCode)
    let self.exitCode = a:exitCode
    try
      call self.OnFinish()
    catch /.*/
      call s:Log(0, "exception while running OnFinish handler")
    endtry
    for i in get(self,'onFinishCallbacks',[])
      if type(i) == 1
        exec i
      else
        call library#Call(i,[self])
      endif
    endfor
    call self.DelTemp()
    call remove(s:status,self['id'])
  endf
  fun! process.DelTemp()
    silent! delete(self.tempfile)
  endf
  fun! process.OnFinish()
    if has_key(self, 'ef')
      call tovl#errorformat#SetErrorFormat(self.ef)
      exec 'cf '.self.tempfile
      cw
    else
      call self.EchoResult()
    endif
  endf
  fun! process.EchoResult()
      echo "process ".self.id. 
            \ (self.exitCode == self.expectedExitCode
            \ ? " finised (success!)"
            \ : " failed with exit code (".self.exitCode.")")
  endf
  fun! process.OnStart()
  endf
  fun! process.Run()
    if type(self.cmd) == 3
      let self.realCmd = map(copy(self.cmd), 'library#Call(v:val)')
    else
      let self.realCmd = library#Call(self.cmd)
    endif
    try
      try
        call self.OnStart()
      catch /.*/
        call s:Log(0, "exception while running OnStart handler")
      endtry
      call s:Log(1, "trying to run command ".string(self.realCmd))
      let s:status[self['id']] = self
      try
        let handlers = config#Get('plugins#tovl#runtaskinbackground#PluginRunTaskInBackground#run_handlers')
        call library#Try(handlers, self)
      catch /.*/
        " try again, without bakground this time
        let self['fg'] = 1
        call library#Try(handlers, self)
      endtry
    catch /.*/
      call s:Log(0,"exception while running command")
    endtry
    return self
  endf
  fun! process.SetProcessId(pid)
    call s:Log(2,"vim process id ".self.id." got pid: ".a:pid)
    let self.processId = a:pid
  endf
  call extend(process, a:p, "force")
  let Dec = config#Get('plugins#tovl#runtaskinbackground#PluginRunTaskInBackground#process_obj_decorator_fun',
        \ {'default' : library#Function('library#Id')})
  return library#Call(Dec, [process])
endf


fun! tovl#runtaskinbackground#DefaultDecorator(p)
  return a:p
  " this could look like this:
  let child = {}
  fun! child.OnStart()
    colorscheme foo
    return self.Parent_OnStart()
  endf
  fun! child.OnFinish()
    colorscheme bar
    cope
    return self.Parent_OnFinish()
  endf
  return p.createChildClass(child)
endf


" =======================  run handlers ======================================
fun! tovl#runtaskinbackground#RunHandlerPython(process)
  if !has('python') | throw "RunHandlerPython: no python support" | endif
  if get(a:process, 'fg', 0) && !has('clientserver') | throw "RunHandlerPython: no client server support!" | endif
  let vim = tovl#runtaskinbackground#Vim()
  " lets hope this vim has clientserver support..

  throw "untested.. the sh way works fine.. So I will only test and fix this if someone needs it"

" if you know a better solution than using g:vimPID than mail me!
let g:vimPID=a:process['id']
let g:use_this_vim = vim
let g:tempfile = a:process['tempfile']
py << EOF
vimPID = vim.eval("g:vimPID")
thisOb = "config#GetG(''tovl#running_background_processes'')[%s]"%(vimPID)
thread=MyThread(thisOb, vim.eval("g:use_this_vim"), vim.eval("v:servername"), vim.eval("v:tempfile"))
thread.start()
EOF
  unlet g:vimPID
  unlet g:use_this_vim
  unlet g:tempfile
  return [1,"python thread started"]
endf

fun! s:CallVimUsingSh(vim,vimcmd)
  " intentionally no quoting to pass $$ and $?
  let S = function('tovl#runtaskinbackground#EscapeShArg')
  return S(a:vim)." --servername ".S(v:servername).' --remote-send \<esc\>:'.a:vimcmd.'\<cr\>' 
endfun

fun! tovl#runtaskinbackground#RunHandlerSh(process)
  let S = function('tovl#runtaskinbackground#EscapeShArg')
  if !get(a:process, 'fg', 0) && !has('clientserver') | throw "RunHandlerSh: no client server support!" | endif
  if has('win16') || has('win32') || has('win64') | throw "RunHandlerSh: win not supported yet!" | endif
  if !executable('/bin/sh') | throw "no /bin/sh found" | endif

  if get(a:process, 'fg',0)
    " run in foreground
    let out = tovl#runtaskinbackground#System(a:process.realCmd, {'status' : a:process.expectedExitCode} )
    call writefile(split(out,"\n"), a:process.tempfile)
    call a:process.Finished(v:shell_error)
  else
    " run in background
    let vim = tovl#runtaskinbackground#Vim()
    " lets hope this vim has clientserver support..
    let tellPid = s:CallVimUsingSh(vim,
          \ S('call config#GetG(''tovl#running_background_processes'')['.a:process.id.']').'".SetProcessId("$$")"')
    let tellResult = s:CallVimUsingSh(vim,
          \ S('call config#GetG(''tovl#running_background_processes'')['.a:process.id.']').'".Finished("$?")"')

    if type(self.cmd) == 3
      let cmd = join(map(copy(a:process.realCmd),
     \ "tovl#runtaskinbackground#EscapeShArg(v:val)"),' ')
    else
      let cmd = a:process:realCmd
    endif
    " FIXME: requiring linux for now..
    call tovl#runtaskinbackground#System(['/bin/sh'], 
      \ {'stdin-text' :  '{ '.tellPid."\n".cmd.'&>'.a:process.tempfile."\n".tellResult.'; } &'} )
  endif
endf

fun! tovl#runtaskinbackground#RunHandlerSystem(opts)
  if !get(a:opts, 'fg', 0) | throw "RunHandlerSystem: no backgrounding support" | endif
  throw "not implemented yet"
endf

fun! tovl#runtaskinbackground#Vim()
  " gvim is more likely to have client server support .. ?
  return library#Try([
   \ library#Function('tovl#runtaskinbackground#VimFilepathByGlibc', {'args' : [5]}),
   \ library#Function('tovl#runtaskinbackground#VimFilepathByGlibc', {'args' : [6]}),
   \ library#Function('if executable("gvim")| return "gvim" | else | throw "no gvim"|endif'),
   \ library#Function('if executable("vim")| return "vim" | else | throw "no vim"|endif')
   \ ])
endf


" get the path of this vim instance
" used in runtaskinbackground.vim
" Luc Hermitte proposed something like:
fun! tovl#runtaskinbackground#VimFilepathByGlibc(v)
  silent! let vimpid = libcallnr("libc.so.".a:v, "getpid", "")
  " matchstr is used to get rid of the newline char
  if vimpid == 0
    throw "libc.so.5 not found"
  else
    let vim = substitute(system("pmap ".vimpid." | sed -n -e 's/.* //' -e '2p'"),"\n\\|\r",'','g') 
    if executable(vim)
      return vim
    else
      throw "no executable found"
    endif
  endif
endfunction

fun! tovl#runtaskinbackground#EscapeShArg(arg)
  " zsh requires []
  return escape(a:arg, ";()*<>| '\"\\`[]")
endf

" usage: vl#lib#system#system#System( ['echo', 'foo'], {'stdin-text' : 'will be ignored by echo', status : 0 })
fun! tovl#runtaskinbackground#System(items, ... )
  let opts = a:0 > 0 ? a:1 : {}
  let cmd = ''
  for a in a:items
    let cmd .=  ' '.tovl#runtaskinbackground#EscapeShArg(a)
  endfor
  if has_key(opts, 'stdin-text')
    let f = tempname()
    " don't know why writefile(["line 1\nline 2"], f, 'b') has a different
    " result?
    call writefile(split(opts['stdin-text'],"\n"), f, 'b')
    let cmd = cmd. ' < '.f
    call s:Log(1, 'executing system command: '.cmd.' first 2000 chars of stdin are :'.opts['stdin-text'][:2000])
  else
    call s:Log(1, 'executing system command: '.cmd)
  endif

  let result = system(cmd)
  if exists('f') | call delete(f) | endif
  let g:systemResult = result

  let s = get(opts,'status',0)
  if v:shell_error != s && ( s != '*')
    let g:systemResult = result
    throw "command ".cmd."failed with exit code ".v:shell_error
     \ . " but ".s." expected. Have a look at the program output with :echo g:systemResult".repeat(' ',400)
     \ . " the first 500 chars of the result are \n".strpart(result,0,500)
  endif
  return result
endfun

if exists('g:pythonthreadclassinitialized') || !has('python')
  finish
endif
let g:pythonthreadclassinitialized=1
py << EOF
from subprocess import Popen, PIPE
import threading
import os
import vim
class MyThread ( threading.Thread ):
  def __init__(self, thisOb, vim, servername, tempfile):
    threading.Thread.__init__(self)
    self.thisOb = thisOb
    self.command = vim.eval("%s['realCmd']"%(thisOb))
    self.vim = vim
    self.tempfile = tempfile
    self.servername = servername

  def run ( self ):
    try:
      popenobj  = Popen(self.cmd,stdout=PIPE,stderr=PIPE)
      self.executeVimCommand("%s.SetProcessId(%s)"%(self.thisOb,popenobj.pid))
      stdoutwriter = open(self.tempfile,'w')
      stdoutwriter.writelines(popenobj.stdout.readlines())
      stdoutwriter.writelines(popenobj.stderr.readlines())
      stdoutwriter.close()
      popenobj.wait()
      self.executeVimCommand("%s.Finished(%d)"%(self.thisOb,popenobj.returncode))
    except Exception, e:
      self.executeVimCommand("echoe '%s'"%("exception: "+str(e)))
    except:
      # I hope command not found is the only error which might  occur here
      self.executeVimCommand("echoe '%s'"%("command not found"))
  def executeVimCommand(self, cmd):
    # can't use vim.command! here because vim hasn't been written for multiple
    # threads. I'm getting Xlib: unexpected async reply (sequence 0x859) ;-)
    # will use server commands again
    popenobj = Popen([self.vim,"--servername","%s"%(self.servername),"--remote-send","<esc>:%(cmd)s<cr>"%locals()])
    popenobj.wait()
EOF


" Thanks to Luc Hermitte <hermitte@free.fr> for his suggestions
" He has written a similar script which can be found here:
"     <http://hermitte.free.fr/vim/ressources/lh-BTW.tar.gz> (still in an
"     alpha stage.)
"     --
"      Luc Hermitte
"      http://hermitte.free.fr/vim/
