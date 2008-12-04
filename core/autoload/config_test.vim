function! s:Dummy()
  " to buffer of dict
  call assert#Equal(
        \ config#Dictionary()['toBuffer']('+','', {'a': 'foo'}),
        \ ["dictionary=", 
        \  "+a:string=foo"], "dictionary to buffer")

  " to buffer of list
  call assert#Equal(
        \ config#List()['toBuffer']('+','', ['a', 'foo']),
        \ ["list=", 
        \  "+string=a", 
        \  "+string=foo"], "list to buffer")

 " test configuration editing in buffer
 call config#EditConfiguration({
       \ 'onWrite' : library#Function('config_test#TestWrite'),
       \ 'getData' : library#Function('config_test#TestData')
       \ })
 " now we should be in a new split buffer and should change the configuration
 %s/b:string=b/b:string=c/g
 " save, this should reload configuration
 normal "ZZ"
 call assert#Equal(g:dummy,[{"a": "a"}, {"b":"c"}], "configuration read and write check")
endfunction

function! config_test#ToBufferFromBufferEq(v, msg)
  let buffer = config#ToBuffer('  ', '', a:v)
  call assert#Equal(a:v, config#FromBuffer(buffer,0,0, '  ','')[1], a:msg)
endfunction

function! config_test#Test()
  let m = expand('<sfile>').' '

  let dict = {"a": {"b": 7}}

  let d = deepcopy(dict)
  call config#RemoveByPath(d, "a.b")
  call assert#Equal({}, d, m." RemoveByPath no keep")

  let d = deepcopy(dict)
  call config#RemoveByPath(d, "a.b", 0)
  call assert#Equal({"a":{}}, d, m." RemoveByPath keep")

  let tovl = config#TOVL()
  try
    let g:tovl = {}
    call config#SetG('config.types', library#EvalWhenRequested(library#Function('config#DefaultTypes')))

    "call s:Dummy()

    " test serialization
    let tests = [
          \ 20,
          \ "abc",
          \ "ab\nc",
          \ [1,2,3],
          \ ["a","b","c"],
          \ {"a":"A", "b":"B"},
          \ {"a":[1,2,3], "b":"B"},
          \ {"a":{"a":[1,2,3], "b":"B"},"b":"B"},
          \ library#Function('doesnt#exist')
          \ ]
    "for i in range(0,len(tests)-1)
    for i in range(0,7)
      let t = tests[i]
      call config_test#ToBufferFromBufferEq(t, m." ".library#Type(t))
      unlet t
    endfor

    call assert#Equal(['a','b'], config#Path('a.b'), m.'config#Path') 

    call assert#Equal('b', config#GetByPath({'a':'b'}, 'a'), m.'GetByPath')
    call assert#Equal('a', config#GetG('a#b#doesntexist', 'a'), m.'default')

    try
      call config#GetG('a#b#doesntexist')
      call assert#Bool(0, m." no default didn't throw exception")
    catch /.*/
    endtry

    for p in ['a', 'b#c']
      call config#SetG(p,p)
      call assert#Equal(config#GetG(p), p, m.string(p))
    endfor

    let t = tempname()
    call writefile([string({'A':'B'})],t)
    let files = config#GetG('config#files',[])
    try
      call config#SetG('config#files', [t])
      call assert#Equal(config#Get('A'), 'B', m."config#Get didn't work")
      " force a different timestamp
      !sleep 1
      call writefile([string({'A':'C'})],t)
      call assert#Equal(config#Get('A'), 'C', m."config#Get rereading config file didn't work")
      call assert#Equal(config#Get('noway','b'), 'b', m."config#Get didn't return default")

      " merge feature:
      call config#SetG('config#A#merge', library#Function('config_test#MergeTest'))
      let t2 = tempname()
      call writefile([string({'A':'C2'})],t2)
      call config#SetG('config#files', [t,t2])
      call assert#Equal(config#Get('A'), 'C2C', m."config#Get didn't return merged config")

      " config write test

      call config#SetG('config#files', [t])
      let clearConfigCache = 'call config#SetG(["scanned_files",string(function("config#EvalFirstLine"))], {})'

      call config#Set(["write","Z"], "Zvalue", t)
      exec clearConfigCache
      call assert#Equal("Zvalue", config#Get("write#Z"), m."write#Z")

      " config write test without flushing
      call config#StopFlushing(t)
      call config#Set(["write","Z2"], "Zvalue2", t)
        " check that option hasn't been written to disk
      call assert#Equal(-1, match(join(readfile(t),""), "Zvalue2"),m."Zvalue22")
      call config#ResumeFlushing(t) " write to disk
      exec clearConfigCache
      call assert#Equal("Zvalue2", config#Get("write#Z2"), m."ZValue2")

    " TODO: add tests for the function feature
    finally
      call config#SetG('config#files', files)
    endtry
  finally
    let g:tovl = tovl
  endtry
endfunction

function! config_test#MergeTest(a,b)
  return a:a.a:b
endfunction

" call config_test#Test()

function! config_test#TestData()
  return [{"a": "a"}, {"b":"b"}]
endfunction

function! config_test#TestWrite()
  let lines = tofl#buffer#LinesOfScratchBuffer()
  let g:dummy = config#FromBuffer(lines,0,0, '  ','')[1]
  setlocal nomodified
endfunction
