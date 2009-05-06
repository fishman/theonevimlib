" author: Marc Weber
" use call
" vl#lib#hl#vim7highlightCurrentLineInActiveWindow#ToggleHighlightCurrentLine() to toggle highlighting of the cursor
" only in active window

" example mapping:
  " noremap <m-h><m-c> :call vl#lib#hl#vim7highlightCurrentLineInActiveWindow#ToggleHighlightCurrentLine()<cr>

function! plugins#buffer#highligh_current_line_in_active_window#PluginHighlightCurrentLineInActiveWindow(p)
  let p = a:p
  let p['Tags'] = ['highlight','current line']
  let p['Info'] = "This script highlights the current line within the active window only"

  let p['defaults']['tags'] = ['hl_current_line']
  " run this to fix prefixes of autoload functions (remember that you can use undo.. :-)
  let p['feat_mapping'] = {
    \ 'toggle_highlighting' : {
    \ 'lhs' : '\hc',
    \ 'rhs' : ':silent! call '.p.s.'.ToggleHighlightCurrentLine()<cr>' }
  \ }

  " put cursor on autolad function and press gf to jump to the file or to create
  " a new file.
  let p['autocommands']['win_enter'] = {
    \ 'events' : 'WinEnter',
    \ 'pattern' : '*',
    \ 'cmd' : "if exists('g:HighlightCurrentLine') && g:HighlightCurrentLine | setlocal cul | endif"
    \  }
  let p['autocommands']['win_leave'] = {
    \ 'events' : 'WinLeave',
    \ 'pattern' : '*',
    \ 'cmd' : "if exists('g:HighlightCurrentLine') && g:HighlightCurrentLine | setlocal nocul | endif"
    \  }
  let p['defaults']['highlight_on_load'] = 1
  let child = {}
  fun! child.Load()
    let g:HighlightCurrentLine=0
    if self.cfg.highlight_on_load
      call self.ToggleHighlightCurrentLine()
    endif
    call self.Parent_Load()
  endf
  fun! child.Unload()
    unlet g:HighlightCurrentLine
    setlocal nocul
    call self.Parent_Unload()
  endf
  function child.ToggleHighlightCurrentLine()
    if !exists('g:HighlightCurrentLine') || g:HighlightCurrentLine==0
      setlocal cul
      let g:HighlightCurrentLine=1
    else
      setlocal nocul
      let g:HighlightCurrentLine=0
    endif
  endfunction
  return p.createChildClass(child)
endfunction
