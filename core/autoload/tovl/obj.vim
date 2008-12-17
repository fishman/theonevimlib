" OO duck typing in vimscript
"
" each child "class" class has a key parent
" see ./obj_test.vim for examples

fun! tovl#obj#NewObject(name)
  " head of names is current class
  let d = {'classes' : [a:name],
        \ }

  " opts: name: the name of the subclass (optional)
  "       extendParent: 1: extend the parent instead of the child
  "                        This can be useful to add additional code
  "                        This way the interface can be simple
  fun! d.createChildClass(dict, ...)
    let opts = a:0 > 0 ? a:1 : {}
    let extendParent = get(opts, 'extendParent', 0)
    let target = extendParent ? self : a:dict

    if has_key(opts,'name')
      let target['classes'] = [opts['name']] + self.classes
    endif

    " now add a Parent_name function for all methods of the parent class
    " if the child does not override it both .name() and Parent_name() will be
    " the same. This won't hurt.
    for m in keys(filter(copy(self), 'type(v:val) == 2'))
      let target['Parent_'.m] = self[m]
    endfor

    if extendParent
      " override methods
      " copy properties and methods
      call extend(self, a:dict, 'force')
    else
      " copy properties and methods
      call extend(target, self, 'keep')
    endif

    return target
  endf

  " only extend parent once
  fun! d.extendParent(FunOrDict)
    if !has_key(self, 'extended_by')
      let self['extended_by'] = []
    endif
    if index(self.extended_by, a:FunOrDict) >= 0
      return self
    endif
    call add(self.extended_by, a:FunOrDict)
    return self.createChildClass(
          \ library#Type(a:FunOrDict) == 4 ? a:FunOrDict : library#Call(a:FunOrDict),
        \ {'extendParent' : 1})
  endf

  " shortcut, can be overridden
  fun! d.loadMissing()
    for e in get(self, 'missing')
      call  self.extendParent(e)
    endfor
    return self
  endf

  " call a method and if there is an error try to print a more meaningfull
  " trace replacing function numbers of this object by method names
  fun! d.DebugCall(name, args)
    try
      return call(self[a:name], a:args, self)
    catch /.*/
      echo v:exception
      echo v:throwpoint
      call plugins#tovl#debug_trace#FindAndPrintPieces(matchstr(v:throwpoint,'.*\zs\S\+\.\.\S\+\ze'),{'self':self})
    endtry
  endfun

  return d
endf
