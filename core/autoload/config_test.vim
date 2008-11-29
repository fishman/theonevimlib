function! config_test#Test()
  let tovl = config#TOVL()
  try
    let g:tovl = {}
    let m = expand('<sfile>').' '

    call assert#Equal(['a','b'], config#Path('a.b'), m.'config#Path') 

    call assert#Equal('b', config#GetByPath({'a':'b'}, 'a'), m.'GetByPath')
    call assert#Equal('a', config#GetG('a.b.doesntexist', 'a'), m.'default')

    try
      call config#GetG('a.b.doesntexist')
      call assert#Bool(0, m." no default didn't throw exception")
    catch /.*/
    endtry

    for p in ['a', 'b.c']
      call config#SetG(p,p)
      call assert#Equal(config#GetG(p), p, m.string(p))
    endfor

    let t = tempname()
    call writefile([string({'A':'B'})],t)
    let files = config#GetG('configFiles',[])
    try
      call config#SetG('configFiles', [t])
      call assert#Equal(config#Get('A'), 'B', m."config#Get didn't work")
      " force a different timestamp
      !sleep 2
      call writefile([string({'A':'C'})],t)
      call assert#Equal(config#Get('A'), 'C', m."config#Get rereading config file didn't work")
      call assert#Equal(config#Get('noway','b'), 'b', m."config#Get didn't return default")

      " merge feature:
      call config#SetG('config.A.merge', library#Function('config_test#MergeTest'))
      let t2 = tempname()
      call writefile([string({'A':'C2'})],t2)
      call config#SetG('configFiles', [t,t2])
      call assert#Equal(config#Get('A'), 'C2C', m."config#Get didn't return merged config")

    " TODO: add tests for the function feature
    finally
      call config#SetG('configFiles', files)
    endtry
  finally
    let g:tovl = tovl
  endtry
endfunction

function! config_test#MergeTest(a,b)
  return a:a.a:b
endfunction

call config_test#Test()
