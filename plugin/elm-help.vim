function! s:FindDocsFile()
  let path_pieces = split(expand('%:p:h'), '/')
  let i = len(path_pieces) - 1

  while i >= 0
    let path = '/' . join(path_pieces[0:i], '/') . '/elm-docs.json'
    if filereadable(path)
      return path
    endif

    let i -= 1
  endwhile
  throw 'Unable to find elm-docs.json'
endfunction

function! s:LoadDocs()
  if has_key(g:, 'elm_docs_cache')
    return g:elm_docs_cache
  endif

  let docs_filename = <SID>FindDocsFile()
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

command! -nargs=? ElmHelp call <SID>ElmHelp(<f-args>)
