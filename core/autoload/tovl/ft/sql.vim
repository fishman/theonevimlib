"|fld   description : some helpers to make accessing SQL databases most easy
"|fld   keywords : <+ this is used to index / group scripts ?+> 
"|fld   initial author : <+ script author & email +>
"|fld   mantainer : author
"|fld   started on : 2008 Sep 14 08:31:10 PM
"|fld   version: 0.0
"|fld   dependencies: <+ vim-python, vim-perl, unix-tool sed, ... +>
"|fld   contributors : <+credits to+>
"|fld   tested on os : <+credits to+>
"|fld   maturity: unusable, experimental
"|fld     os: <+ remove this value if script is os independent +>
"|
"|H1__  Documentation
"|
"|+     Also have a look at dbext on vim.org which has much more features

" retuns the text
" a command is separated from other commands either
" by empty lines or by ; (at the end of line)
function! tovl#ft#sql#ThisSQLCommand()
  if exists('b:thisSQLCommand')
    return b:thisSQLCommand()
  endif
  let nr = line('.')
  let up = nr -1
  let down = nr
  while up > 0 && getline(up) !~ ';$\|^\s*$'
    let up = up - 1
  endwhile
  while down <= line('$') && getline(down) !~ ';$\|^\s*$'
    let down = down + 1
  endwhile
  return getline(up+1,down)
endfunction


function! tovl#ft#sql#UI()
  Nnoremap <buffer> <F2> :echo b:db_conn.query(join(tovl#ft#sql#ThisSQLCommand(),"\n"))<cr>
  Vnoremap <buffer> <F2> y:echo b:db_conn.query(@")<cr>
endfunction

" =========== completion =============================================
" what one of [ identifier, module ]
function! tovl#ft#sql#Complete(findstart, base)
    "findstart = 1 when we need to get the text length
    if a:findstart == 1
        let [bc,ac] = tovl#buffer#SplitCurrentLineAtCursor()
        return len(bc)-len(matchstr(bc,'\%(\a\|\.\)*$'))
    "findstart = 0 when we need to return the list of completions
    else
      if !exists('b:db_conn')
        echoe "b:db_conn not set, call tovl#ft#sql#Connect(dbType,settings) to setup the connection"
        return []
      endif
      let text = tovl#ft#sql#ThisSQLCommand()
      let words = split(join(text,"\n"),"[\n\r \t'\"()\\[\\],]")
      let tables = b:db_conn.tables()

      let l = matchlist(a:base,'\([^.]*\)\.\([^.]*\)')
      if len(l) > 2
        let alias = l[1]
        let aliasP = alias.'.'
        let base = l[2]
      else
        let alias = ''
        let aliasP = ''
        let base = a:base
      endif

      let tr = b:db_conn['regex']['table']
      let pat = '\zs\('.tr.'\)\s\+\cas\C\s\+\('.tr.'\)\ze' 
      let pat2 = b:db_conn['regex']['table_from_match']
      let aliases = {}
      for aliasstr in tovl#regex#regex#MatchAll(join(text,"\n"),pat)
        let l = matchlist(aliasstr, pat)
        if len(l) > 2
          let aliases[matchstr(l[2],pat2)] = matchstr(l[1], pat2)
        endif
      endfor

      let [bc,ac] = tovl#buffer#SplitCurrentLineAtCursor()
      " add table completion
      " don't add table completion if cursor is located after a SELECT
      " note that something like SELECT id, (SELECT .. FROM WHERE) ... could be valid
      if alias == '' && !(bc =~ '\cSELECT\C[^()]*$' && !bc =~ 'FROM.*$')
        for t in tables
          if t =~ '\%('.tovl#ui#match#AdvancedCamelCaseMatching(base).'\)\|^'.base
            call complete_add({'word' : t, 'menu' : 'a table'})
          endif
        endfor
      endif

      " before AS or after SELECT ... FROM, INSERT INTO .. CREATE / DROP / ALTER TABLE only table names will be shown
      if (bc =~ '\c\%(FROM[^(]*\s\+\|JOIN\s\+\|INTO\s\+\|TABLE\s\+\)\C$' && bc !~ '\cWHERE' ) || ac =~ '^\s*as\>'
        return []
      endif

      " field completion
      let table = get(aliases, alias,'')
      if alias != '' && table == ''
        let noAliasMatchWarning = ' ! alias not defined or table not found'
      else
        let noAliasMatchWarning = ''
      endif

      if table == ''
        let usedTables = tovl#list#Intersection(tables, words)
      else
        let usedTables = [table]
      endif
      let  g:usedTables = usedTables
      let fields = []
      for table in usedTables
        for f in b:db_conn['fields'](table)
          " maybe cache these regex - is it too slow?
          if f =~ '^\%('.tovl#ui#match#AdvancedCamelCaseMatching(base).'\)\|^'.base
            call complete_add({'word' : aliasP.f, 'abbr' : f, 'menu' : 'field of '.table.noAliasMatchWarning })
          endif
        endfor
        call complete_check()|
      endfor
      return []
    endif
endfunction

" =========== selecting dbs ==========================================

" of course it's not a real "connection". It's an object which knows how to
" run the cmd line tools
function! tovl#ft#sql#Connect(dbType,settings)
  let types =  { 'mysql' : function('tovl#ft#sql#MysqlConn') }
  let b:db_conn = types[a:dbType](a:settings)
endfunction

" the following functions (only MySQL implemented yet) all return 
" an "object" having the function
" query(sql)      runs any query and returns the result from stderr and stdout
" tables()        list of tables
" fields(table)   list of fields of the given table
" invalidateSchema() removes cached schema data
" schema          returns the schema
" regex.table  : regex matching a table identifier


" conn = attribute set
" user : 
" password :
" database : (optional)
" optional:
" host :
" port :
" or
" cmd : (this way you can even use ssh mysql ...)
function! tovl#ft#sql#MysqlConn(conn)
  let conn = a:conn
  let conn['regex'] = {
    \ 'table' :'\%(`[^`]\+`\|[^ \t`]\+\)' 
    \ , 'table_from_match' :'^`\?\zs[^`]*\ze`\?$' 
    \ }
  if ! has_key(conn,'cmd')
    let cmd=['mysql']
    if has_key(conn, 'host')
      call add(cmd,'-h') | call add(cmd,conn['host'])
    endif
    if has_key(conn, 'port')
      call add(cmd,'-P') | call add(cmd,conn['port'])
    endif
    if has_key(conn, 'user')
      call add(cmd,'-u') | call add(cmd,conn['user'])
    endif
    if has_key(conn, 'password')
      call add(cmd,'--password='.conn['password'])
    endif
    let conn['cmd'] = cmd
  endif

  function! conn.invalidateSchema()
    let self['schema'] = {'tables' : {}}
  endfunction
  call conn['invalidateSchema']()

  function! conn.databases()
    return tovl#list#MapIf(
            \ split(tovl#runtaskinbackground#System(self['cmd']+["-e",'show databases\G']),"\n"),
            \ "Val =~ '^Database: '", "matchstr(Val, ".string('Database: \zs.*').")")
  endfun

  " output must have been created with \G, no multilines supported yet
  function! conn.col(col, output)
    return tovl#list#MapIf( split(a:output,"\n")
            \ , "Val =~ '^\\s*".a:col.": '", "matchstr(Val, ".string('^\s*'.a:col.': \zs.*').")")
  endfunction

  if !has_key(conn,'database')
    let conn['database'] = tovl#ui#choice#LetUserSelectIfThereIsAChoice(
      \ 'Select a mysql database', conn['databases']())
  endif

  function! conn.tables()
    " no caching yet
    return tovl#list#MapIf(
            \ split(tovl#runtaskinbackground#System(self['cmd']+[self.database,"-e",'show tables\G']),"\n"),
            \ "Val =~ '^Tables_in[^:]*: '", "matchstr(Val, ".string('Tables_in[^:]*: \zs.*').")")

  endfun

  function! conn.loadFieldsOfTables(tables)
    for table in a:tables
      let r = self.query('describe `'.table.'`\G')
      let self['schema']['tables'][table] = { 'fields' : self.col('Field',r) }
    endfor
  endfunction

  function! conn.fields(table)
    if !exists('self["schema"]["tables"]['.string(a:table).']["fields"]')
      call self.loadFieldsOfTables([a:table])
    endif
    return self["schema"]["tables"][a:table]['fields']
  endfunction

  function! conn.query(sql)
    return tovl#runtaskinbackground#System(self['cmd']+[self['database']],{'stdin-text': a:sql})
  endfun


  return conn
endfunction
