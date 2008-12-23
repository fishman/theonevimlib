fun! tovl#dict#CopyKeys(dict, keys, mustExist)
  let r = {}
  for k in a:keys
    if has_key(a:dict, k)
      let r[k] = a:dict[k]
    else
      if a:mustExist
        throw "missing key ".k
      endif
    endif
  endfor
  return r
endf
