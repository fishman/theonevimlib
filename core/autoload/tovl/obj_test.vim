fun! tovl#obj_test#Test() 
  let m = expand('<sfile>').' '

  let a = tovl#obj#NewObject('Base')
  let a['missing'] = [ library#Function('tovl#obj_test#Missing') ]
  fun! a.TestNoOverride() 
    return ["no override"]
  endf
  fun! a.TestOverride()
    return ["test override"]
  endf

  " What a pity that vimscript doesn't know about anonymous classes which can
  " be found in javascript
  let child = {}
  fun! child.TestOverride() 
    return self.Parent_TestOverride() + ["ok"]
  endf
  let b = a.createChildClass(child, {'name' : "child"})

  " trivial, just call parent functions. Should not have been changed
  call assert#Equal(["no override"], a.TestNoOverride(), m.' 1')
  call assert#Equal(["test override"], a.TestOverride(), m.' 2')

  " test child functions
  call assert#Equal(["no override"], b.TestNoOverride(), m.' 3')
  call assert#Equal(["test override", "ok"], b.TestOverride(), m.' 4')

  call assert#Equal("missing", b.loadMissing().MissingFunc(), m.' 5')
endf

fun! tovl#obj_test#Missing()
  let c = {}
  fun! c.MissingFunc()
    return "missing"
  endf
  return c
endf

call tovl#obj_test#Test()
