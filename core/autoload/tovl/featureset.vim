" features
" command or 
" mapping    ---| tag A
"           `-  | tag B  -------- | tag B ---- buffer
"               |                 | tag C ---' 
"               | customizable    |
"                                 | customizable
"
" mappings or commands are tagged.
" than you add all mappigns having one tag to a buffer..
" It's better than just filetypes because you can't assign multiple tags
" to a buffer. One tag could be sql another php and the next html..
" Maybe you wan't all 3 feature sets when editing php files.

" === dict representation of commands: ===

" command keys
" label : description of the command
" name : the command name
" buffer : not set or 1 (is this a buffer only mapping ?)
" cmd : the command text which will be executed
" attrs : extra attrs as string such as -complete, -bang, -bar, -args (no  -buffer here !)
" args : optional : one of  0,1,*,? or +

" === dict representation of mappings : ===
" label : description
" lhs : ...
" rhs : ...
" mode : one of v n i c empty 
" buffer : not set or 1 (is this a buffer only mapping ?)

" === dict representation of a completion func ===
" completion_func : function reference (see tovl/ui/multiple_completions.vim)
" description: a description about what this function does (will be shown when
" there are more than one to choose from..)


" All three types (mappings, commands, completion functions) also have the
" following keys:
"
" plugin : the name of the plugin to which this command belongs
" tags : a set of tags.


"  It would be slow to do a bufdo for each new mapping.. That's why we collect
"  new items in _to_be_added first. Then after all plugins have been loaded
"  (added) we'll add them

" =============================================================
" user interface of this file
" =============================================================
" see ui plugin: core/autoload/plugins/tovl/featureset.vim
"
" a plugin registers a new feature item:
"   call ModifyFeatureItem({}, "add" or "del")
" However the default plugin code does this for you
"
" You add a tag to the global or buffer tag list:
"   call tovl#featureset#ModifyTags(buffor_or_global,['sql'], ['php'])
" Again the cfg.tags options and cfg.tags_buftype should do this for you

fun! s:Log(level, msg)
  call tovl#log#Log("tovl#featureset",a:level, a:msg)
endf
fun! s:LogExec(level, msg)
  call tovl#log#Log("tovl#featureset",a:level, "executing :\n".a:msg)
  exec a:msg
endf

" s:mappings and s:commands contain a list of commands and mappings.
let s:items = config#GetG('tovl#features#items_by_feature', {'set' : 1, 'default' : {}})
let s:lhsMap = config#GetG('config#lhsMap', { 'default' : library#Function('library#Id') })

let s:pd_add = config#GetG('tovl#features#postbone_add', {'set' : 1, 'default' : {}})
let s:pd_del = config#GetG('tovl#features#postbone_del', {'set' : 1, 'default' : {}})
if !exists('s:next_id') 
  " initialize empty values:
  let s:next_id = 0

  " this setting is untested.. I'll finish the implementation if everything
  " gets to slow. Isn't the case here..
  let s:postbone = 0
  let g:tovl_feature_id_counts = {}
  let g:tovl_feature_tags = []
  let cmd = 'let b:tovl_feature_tags = [] | let b:tovl_feature_id_counts = {}'
  exec 'bufdo '.cmd
  augroup TOVL_FEATURESET
    exec 'autocmd BufReadPre,FileReadPre *  '.cmd
  augroup end
endif

fun! tovl#featureset#ListItems(filter)
  let l = []
  for t in keys(s:items)
    for i in s:pd_del[t]
      exec 'if '.a:filter.' | then call add(l, i) | endif'
    endfor
  endfor
  return l
endf

" action = add or del
fun! tovl#featureset#ModifyFeatureItem(i,action)
  let s:next_id = s:next_id +1
  let a:i['id'] = s:next_id
  " completion functions are always per buffer
  if has_key(a:i, 'completion_func')
    let a:i['buffer'] = 1
  endif
  " add to postboned dict:
  for t in a:i['tags']
    let s:pd_{a:action}[t] = get(s:pd_{a:action}, t,[])
    call add(s:pd_{a:action}[t], a:i)
  endfor
  if !s:postbone
    call tovl#featureset#Apply()
  endif
endf

fun! tovl#featureset#ModifyTags(buffer, tags_add, tags_del)
  let v = a:buffer ? 'b' : 'g'
  let add = tovl#list#Difference(a:tags_add, {v}:tovl_feature_tags)
  let del = tovl#list#Intersection(a:tags_del, {v}:tovl_feature_tags)
  call s:Log(2,'modifying tags'.a:buffer.' '.string(add).'/'.string(a:tags_add).' '.string(del))
  call s:WhenTagged(a:buffer, del, function('s:RemoveItem'), s:items)
  call s:WhenTagged(a:buffer, add, function('s:AddItem'), s:items)
  let {v}:tovl_feature_tags = tovl#list#Difference({v}:tovl_feature_tags, del)
  call extend({v}:tovl_feature_tags, add)
endf

fun! tovl#featureset#Apply()
  " apply everything postboned..
  " remove, then add (buffer options)
  bufdo call s:WhenTagged(1, b:tovl_feature_tags, function('s:RemoveItem'), s:pd_del)
   \ | call s:WhenTagged(1, b:tovl_feature_tags, function('s:AddItem'), s:pd_add)

  call s:WhenTagged(0, g:tovl_feature_tags, function('s:RemoveItem'), s:pd_del)
  call s:WhenTagged(0, g:tovl_feature_tags, function('s:AddItem'), s:pd_add)

  " update s:items
  for t in keys(s:pd_del)
    for i in s:pd_del[t]
      call remove(s:items[t], i)
    endfor
  endfor
  for t in keys(s:pd_add)
    for i in s:pd_add[t]
      let s:items[t] = get(s:items,t,[])
      call add(s:items[t], i)
    endfor
  endfor
  " empty pd_add pd_del
  let s:pd_add = {}
  let s:pd_del = {}
endf

fun! s:WhenTagged(buffer, tags, f, d)
  for t in keys(a:d)
    if index(a:tags, t) >= 0
      for i in a:d[t]
        if get(i,'b',0) == a:buffer
          call call(a:f, [i])
        endif
      endfor
    endif
  endfor
endf

fun! s:AddItem(i)
  let b = get(a:i,'buffer',0)

  " increment counter. If item has already been added return
  let id = a:i['id']
  let v = (b ? 'b:' : 'g:').'tovl_feature_id_counts'
  let was = get({v}, id,0)
  let {v}[id] = 1+ was
  if was > 0 | return | endif
  call s:Log(2,'adding feature item '.string(id))

  " add feature
  if has_key(a:i, 'lhs')
    " its a mapping
    call s:LogExec(2, get(a:i,'m','').'noremap '.(b ? '<buffer>' : '').' '
          \ .library#Call(s:lhsMap, [a:i['lhs']]).' '
          \ .a:i['rhs'])
  elseif has_key(a:i, 'cmd')
    " its a command
    call s:LogExec(2, 'command! '.(b ? '-buffer' : '').' '
       \ .get(a:i,'attrs','').' '
       \ .a:i['name'].' '
       \ .a:i['cmd'])
  elseif has_key(a:i, 'completion_func')
    call tovl#ui#multiple_completions#RegisterBufferCompletionFunc(a:i)
  else
    call (0, "unkown item to be added ? How to handle this? ".string(a:i)
  endif
endf

fun! s:RemoveItem(i)
  let b = get(a:i,'buffer',0)
  " decrement counter. Only remove if counter is zero
  let id = a:i['id']
  let v = (b ? 'b:' : 'g:').'tovl_feature_id_counts'
  let {v}[id] -= 1
  if {v}[id] > 1 | return | endif
  call s:Log(2,'removing feature item '.string(id))

  if has_key(a:i, 'lhs')
    " its a mapping
    call s:LogExec(2, get(a:i,'m','').'unmap '.(b ? '<buffer>' : '').' '
          \ .library#Call(s:lhsMap, [a:i['lhs']]))
  elseif has_key(a:i, 'cmd')
    " its a command
    call s:LogExec(2, 'delc '.a:i['name'])
  elseif has_key(a:i, 'completion_func')
    call tovl#ui#multiple_completions#UnregisterBufferCompletionFunc(a:i)
  else
    call (0, "unkown item to be added ? How to handle this? ".string(a:i)
  endif
endf


" worker function for ui commands
fun! tovl#featureset#CommandAction(buffer, ...)
  if a:0 == 0
    " list, do nothing
    echo "== active tags =="
    let v = (a:buffer ? 'b:' : 'g:').'tovl_feature_tags'
    for i in {v} | echo i | endfor
    return 
  endif
  let add = []
  let remove = []
  for i in a:000
    if i[0] == '-'
      call add(remove, i[1:])
    else
      call add(add, i)
    endif
  endfor
  call tovl#featureset#ModifyTags(a:buffer,add, remove)
endfun

" completion function for commands
fun! tovl#featureset#CommandCompletion(buffer, A,L,P)
  let beforeC= a:L[:a:P-1]
  let word = matchstr(beforeC, '\zs\S*$')
  let v = (a:buffer ? 'b:' : 'g:').'tovl_feature_tags'
  if word[:0] == '-'
    return map( filter(copy({v}),'v:val =~ '.string('^'.word[1:])),
              \ string('-').'.v:val')
  else
    let tags = []
    for k in keys(s:items)
      if !empty(filter(copy(s:items[k]),'get(v:val,"buffer",0) == '.a:buffer))
        call add(tags, k)
      endif
    endfor
    return vl#lib#listdict#list#Difference(tags, {v})
  endif
endf

fun! tovl#featureset#CommandCompletionGlobal(...)
  return call(function('tovl#featureset#CommandCompletion'), [0] + a:000)
endf

fun! tovl#featureset#CommandCompletionBuffer(...)
  return call(function('tovl#featureset#CommandCompletion'), [1] + a:000)
endf
