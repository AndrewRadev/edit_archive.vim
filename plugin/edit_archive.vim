" Prevent built-in tar and zip plugins from loading
let g:loaded_tarPlugin = 1
let g:loaded_tar       = 1
let g:loaded_zipPlugin = 1
let g:loaded_zip       = 1

" Disable tar/zip plugin if it's loaded anyway
augroup tar
  autocmd!
augroup END
augroup zip
  autocmd!
augroup END

augroup edit_archive
  autocmd!

  autocmd BufReadCmd *.zip             call s:ReadArchive(expand('<afile>'))
  autocmd BufReadCmd *.rar             call s:ReadArchive(expand('<afile>'))
  autocmd BufReadCmd *.tar             call s:ReadArchive(expand('<afile>'))
  autocmd BufReadCmd *.tar.{gz,bz2,xz} call s:ReadArchive(expand('<afile>'))

  autocmd BufWriteCmd *.zip             call s:UpdateArchive()
  autocmd BufWriteCmd *.rar             call s:UpdateArchive()
  autocmd BufWriteCmd *.tar             call s:UpdateArchive()
  autocmd BufWriteCmd *.tar.{gz,bz2,xz} call s:UpdateArchive()
augroup END

function! s:ReadArchive(archive)
  let b:archive = edit_archive#archive#New(a:archive)
  call s:SetupArchiveBuffer()

  nnoremap <buffer> <cr>       :call <SID>EditFile('edit')<cr>
  nnoremap <buffer> gf         :call <SID>EditFile('edit')<cr>
  nnoremap <buffer> <c-w>f     :call <SID>EditFile('split')<cr>
  nnoremap <buffer> <c-w><c-f> :call <SID>EditFile('split')<cr>
  nnoremap <buffer> <c-w>gf    :call <SID>EditFile('tabedit')<cr>

  command! -buffer -nargs=1 -complete=dir Extract call b:archive.ExtractAll(<f-args>)
endfunction

function! s:EditFile(operation)
  let archive  = b:archive
  let filename = s:FilenameOnLine()
  let tempname = archive.Tempname(filename)

  exe a:operation.' '.tempname
  let b:archive = archive
  call b:archive.SetupWriteBehaviour(filename)
  command! -buffer Archive call b:archive.GotoBuffer()
endfunction

function! s:UpdateArchive()
  let saved_cursor = getpos('.')

  call cursor(1, 1)
  call search('=====', 'W')
  let first_line = nextnonblank(line('.') + 1)
  if first_line <= 0
    call setpos('.', saved_cursor)
    return
  endif

  let files             = b:archive.Filelist()
  let remaining_indices = range(len(files))

  for line in getline(first_line, line('$'))
    if line =~ '^\d\+.'
      " then it's an existing entry
      let index         = str2nr(matchstr(line, '^\d\+\ze.'))
      let path          = strpart(line, strlen(index) + 2)
      let original_path = files[index]
      call remove(remaining_indices, index(remaining_indices, index))

      if original_path != path
        call b:archive.Rename(original_path, path)
      endif
    else
      " it's a new entry
      call b:archive.Add(line)
    endif
  endfor

  for index in remaining_indices
    let missing_path = files[index]
    call b:archive.Delete(missing_path)
  endfor

  call s:SetupArchiveBuffer()

  call setpos('.', saved_cursor)
endfunction

function! s:Enumerate(file_list)
  let file_count      = len(a:file_list)
  let width           = strlen(file_count - 1)
  let enumerated_list = []

  for i in range(file_count)
    call add(enumerated_list, printf('%'.width.'s. ', i).remove(a:file_list, 0))
  endfor

  return enumerated_list
endfunction

function! s:SetupArchiveBuffer()
  %delete _

  let banner = []
  call add(banner, 'File: '   . b:archive.name)
  call add(banner, 'Format: ' . b:archive.format)
  call add(banner, 'Size: '   . b:archive.size)
  call add(banner, repeat('=', len(banner[0])))
  call append(0, banner)

  let contents = s:Enumerate(b:archive.Filelist())
  set filetype=archive
  setlocal buftype=acwrite
  setlocal bufhidden=hide
  setlocal isfname+=:
  call append(line('$'), contents)
  normal! gg
  set nomodified
  let short_filename = fnamemodify(b:archive.name, ':~:.')
  let filename = 'archive://'.short_filename
  silent exec 'keepalt file ' . escape(filename, '[')
endfunction

function! s:FilenameOnLine()
  let line = getline('.')
  if line !~ '^\s*\d\+\.'
    return ''
  endif

  return substitute(line, '^\s*\d\+\. ', '', '')
endfunction
