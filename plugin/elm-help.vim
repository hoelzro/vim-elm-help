function! s:FindDocsFile()
  let path_pieces = split(expand('%:p:h'), '/')
  let i = len(path_pieces) - 1

  while i >= 0
    let dir = '/' . join(path_pieces[0:i], '/')
    if filereadable(dir . '/elm-package.json')
      return dir . '/elm-docs.json'
    endif

    let i -= 1
  endwhile
  throw 'Unable to find elm-package.json'
endfunction

function! s:LoadDocs()
  if has_key(g:, 'elm_docs_cache')
    return g:elm_docs_cache
  endif

  let docs_filename = <SID>FindDocsFile()

  if !filereadable(docs_filename)
    throw 'Docs have not been created yet'
  endif
  let lines = readfile(docs_filename)
  let raw_content = join(lines, "\n")
  let g:elm_docs_cache = json_decode(raw_content)

  return g:elm_docs_cache
endfunction

function! s:ElmHelp(...)
  if a:0 > 0
    let name = a:1
  else
    let name = expand('<cWORD>')
  endif

  let docs = <SID>LoadDocs()

  topleft new
  setlocal noswapfile
  setlocal buftype=nowrite
  setlocal bufhidden=delete
  setlocal nonumber
  setlocal nowrap
  setlocal norightleft
  setlocal foldcolumn=0
  setlocal nofoldenable
  setlocal modifiable
  call append(0, split(docs[name]['comment'], '\n'))
  if has_key(docs[name], 'type')
    call append(0, [ name . ' : ' . docs[name]['type'], '' ])
  endif
endfunction

let s:build_docs_script = expand('<sfile>:p:h:h') . '/bin/build-docs.pl'

function! s:ElmBuildDocs()
  let lines = systemlist('perl ' . s:build_docs_script)
  if type(lines) == v:t_string && lines == ''
    echomsg 'An error occurred when running the database building script'
  endif
  if v:shell_error != 0 && v:shell_error != 1
    " 0 is success, 1 is our special error for "don't worry about it"
    echomsg 'An error occurred when running the database building script'
  endif
  let outpath = <SID>FindDocsFile()
  call writefile(lines, outpath)
  unlet g:elm_docs_cache
endfunction

command! -nargs=? ElmHelp call <SID>ElmHelp(<f-args>)
command! -nargs=0 ElmBuildDocs call <SID>ElmBuildDocs()
