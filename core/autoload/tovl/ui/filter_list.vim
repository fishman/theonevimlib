" filter list displays a list of items
" you can white / black filter them by regular expressions (similar to the
" tlib TToC command
" However you can edit the filters afterwards and select the cols which should
" be shown

fun! tovl#ui#filter_list#ListTest()
  call tovl#ui#filter_list#ListView({
	\ 'aligned' : 1,
	\ 'items' : [ {"aa" : "a\nAAAAAAAAAAA", 'bb' : "bbbbbbbbbbbbb\nB" }, 
		   \  {"aa" : "2a\n2AAAAAAAAAAAA", "bb" : "2 bbbbbbbbbbbbb\n2B"},
		   \  {"aa" : "XXX", "bb" : "YY"} ],
	\ })

endfun
" opens a new filtered list
" keys of opts parameters:
" continuation: This function will be called with the selected items
" items: { key : (string or dict) }
"        items willl be modified. use copy(youritems) as argument to prevent
"        this. An item is either a string or a dict 
"        (eg {'file' : .., 'line': ... , 'msg' : .. )
" keys: list of keys to be shown (optional)
" filter: list of inital filters which must be applied
" contains [ { filter: .. , keep : .. }, ] see FilterItems() below
" aligned: default 0
" sp_cmd: the command to be used to create the new buffer (default ':e')
" init : 0 / 1 (default 1): wether to show the view right now
"
" If you don't like the default view you can override UpdateDisplay
"
" Usage examples of this list control:
" - db results
" - replacement of the quickfix window
" - select a buffer etc
fun! tovl#ui#filter_list#ListView(opts)
  let d = tovl#obj#NewObject("filter_list")
  let d.items = a:opts.items
  let d.aligned = get(a:opts, 'aligned', 0)
  let d.sep = '  '
  let d.filter = get(a:opts, 'filter', [])
  let d.sp_cmd = get(a:opts, 'sp_cmd', 'e')
  let d.inCharLoop = 0
  let d.allKeys = {}
  if has_key(a:opts,'keys')
    let d.keys = a:opts.keys
  endif

  " cache already filtered items in case we want to view really long results
  " contains [ { filter : { filter: .. , keep : .. } , items : }, { filter : items } ]
  let d.cached = []
  " id of buffer
  let d.buffer = -1

  fun d.HelpText()
    return [ "you've entered the the help of the powerful filtered view buffer",
	   \ "",
	   \ "type f to start filtering items by regex",
	   \ "type F to start dropping items by regex",
	   \ "k / K will ask you for the key to apply the filter to first",
	   \ "apply the filter by <cr> and press <cr> again to select item",
	   \ "",
	   \ "use :ShowAppliedFilters to list active filters",
	   \ "use :ToggleAlignment to toggle alignment",
	   \ "",
	   \ "TODO: Implement sorting, implement interface to change keys (displayed columns)"
	   \ ]
  endfun

  " create new scratch buffer
  " preprocess items calculating line count and maxwidth for all items
  fun d.NewBufferAndInit()
    let self.bufferId = bufnr(bufname('%'))
    for idx in range(0,len(self.items)-1)
      if type(self.items[idx]) != 4
	" no dict yet, make it one
	let self.items[idx] = {'line' : i}
      endif
      let new = {}
      for [k,v] in items(self.items[idx])
	let lines = split(v,"\n")
	let self.items[idx][k] = { 'text' : v, 'rows' : len(lines), 'cols' : max(map(copy(lines),'len(v:val)')), 'lines' : lines }
	let self.allKeys[k] = 1
      endfor
    endfor
    call tovl#scratch_buffer#ScratchBuffer({
	  \ 'help' : library#Function(self.HelpText,{ 'self' : self }),
	  \ 'getContent' : library#Function(self.DisplayLines, {'self' : self}),
	  \ 'sp_cmd' : self.sp_cmd })
    let b:filtered_view = self
    command! -buffer -nargs=0 ToggleAlignment call b:filtered_view.ToggleAlignment()
    command! -buffer -nargs=0 ShowAppliedFilters call b:filtered_view.ShowAppliedFilters()
    command! -buffer -nargs=0 RemoveFilters call b:filtered_view.RemoveFilters()
    noremap <buffer> f :call b:filtered_view.DebugCall('FilterFromKeyboard', [1])<cr>
    " noremap <buffer> f :call b:filtered_view.FilterFromKeyboard(1)<cr>
    noremap <buffer> F :call b:filtered_view.FilterFromKeyboard(0)<cr>
    "noremap <buffer> k
    "noremap <buffer> K
  endfun

  " user interface
  fun d.ToggleAlignment()
    let self.aligned = !self.aligned
    call self.UpdateDisplay()
  endfun
  fun d.ShowAppliedFilters()
    for i in self.filter | echo string(i) | endfor
  endfun
  fun d.RemoveFilters()
    let self.filter = []
    call self.UpdateDisplay()
  endfun

  " updates the filter cache and returns the final filtered items
  fun d.FilteredItems()
    " update cache
    let idx = 0
    let items = self.items
    for idx in range(0, len(self.filter)-1)
      if idx +1 > len(self.cached) || self.cached[idx]['filter'] != self.filter[idx]
	let self.cached = self.cached[:idx-1]
	let items = self.FilterItem(copy(items), self.filter[idx])
	call add(self.cached, { 'items' : items, 'filter' : self.filter[idx]})
      else
	let items = self.cached[idx]['items']
      endif
    endfor
    return items
  endfun

  fun d.UpdateDisplay()
    GetContents
    redraw
  endfun

  fun d.DisplayLines()
    let items = self.FilteredItems()
    let num_width = printf('%.0f', trunc(log10(len(items))+1))
    if self.aligned
      " get column width.. (probably will not work with unicde characters.. I
      " don't have a better solution)
      let maxlens={}
      for i in items
	for [k,v] in items(i)
	  if get(maxlens,k,0) < v.cols
	    let maxlens[k] = v.cols
	  endif
	endfor
      endfor
    endif

    " format lines
    let lines = []
    for idx in range(0,len(items)-1)
      let i = items[idx]
      let keys = has_key(self,'keys')
	    \ ? tovl#list#Intersection(self.keys, keys(i))
	    \ : keys(i)
      let fmt_startA = '%'.num_width.'s)'
      let fmt_startB = '%'.num_width.'s'
      let fmt = ''
      let args =  [i]
      let cols = []
      for k in keys
	let fmt .= self.sep.'%'.(self.aligned ? maxlens[k] : i[k]['cols']).'s'
	call add(cols, i[k])
      endfor
      for row in range(0, max([1] + map(copy(cols),'v:val["rows"]'))-1)
	let fmt_args = row == 0 ? [fmt_startA.fmt, idx] :  [fmt_startB.fmt, '']
	for c in cols
	  call add(fmt_args, c.rows < row ? '' : c.lines[row])
	endfor
	call add(lines, call('printf', fmt_args))
      endfor
    endfor
    " update stauts line to show last applied filter
    if empty(self.filter)
      let text = 'no filter applied'
    else
      let text = len(self.filter).' '.string(self.filter[-1])
    endif
    if self.inCharLoop
      let text .= 'press ESC to exit getchar() loop'
    endif
    exec 'setlocal statusline='.escape(text,' ')
    return lines
  endf

  " filter = keys :
  "  filter = string to be executed containing Val
  "  keep = 1  keep on match 
  "       = 0  drop on match
  "  key (optional)
  " optional: key of dict if dict
  fun d.FilterItem(items, filter)
    let filter = a:filter.filter
    let keep = a:filter.keep

    for idx in reverse(range(0, len(a:items)-1))
      let i = a:items[idx]
      if has_key(a:filter,'key')
	let key = a:filter.key
	if has_key(i, key)
	  " key given, only filter by this column
	  let Val = i[key]['text']
	  exec 'let any = '.filter
	else
	  let any = 0
	endif
      else
	let any = 0
	" no key given, try all
	for x in values(i)
	  let Val = x['text']
	  exec 'let any = '.filter
	  if any | break | endif
	endfor
      endif
      if any != keep
	echo 'removing '.string(i)
	call remove(a:items, idx)
      endif
    endfor
    return a:items
  endfun

  " gets a regular expresion filter by keybaord and updates the display while
  " you're typing. The regex ist shown in the statusline
  fun d.FilterFromKeyboard(keep, ...)
    let self.inCharLoop = 1
    try
      let key_text = a:0 > 0 ? 'key : '.a:1 : ''
      let filter_bak = self.filter
      let filter = copy(self.filter)
      let filter_new = ''
      while 1
	let c=getchar()
	if index([13,10],c) >= 0
	  " c-j or return, accept new filter
	  return
	elseif index([27], c) >=0
	  " esc, abort
	  let self.filter = filter_bak
	  call self.UpdateDisplay()
	  return
	else
	  if type(c) == 0
	    let c = nr2char(c)
	  endif
	  if c == "\<bs>"
	    let filter_new = filter_new[:-2]
	  else
	    let filter_new .= c
	  endif
	  let d = {'keep' : a:keep, 'filter' : 'Val =~ '.string(filter_new) }
	  if a:0 > 0
	    let d['key'] = a:1
	  endif
	  let self.filter = copy(filter_bak)
	  call add(self.filter, d)
	  call self.UpdateDisplay()
	endif
      endwhile
    finally
      let self.inCharLoop = 1
    endtry
  endfun
  if get(a:opts,'init',1)
    try
      call d.NewBufferAndInit()
    catch /.*/
      echo v:exception
      echo v:throwpoint
      call plugins#tovl#debug_trace#FindAndPrintPieces(matchstr(v:throwpoint,'.*\zs\S\+\.\.\S\+\ze'),{'view_list':d})
    endtry
  endif
endfun

call tovl#ui#filter_list#ListTest()
