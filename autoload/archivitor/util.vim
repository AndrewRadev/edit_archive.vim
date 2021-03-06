function! archivitor#util#System(command, ...)
  let args = [a:command]
  call extend(args, a:000)

  let result = call('archivitor#util#SilentSystem', args)

  if v:shell_error
    echomsg "System error: Command: ".result
    echoerr "System error: Result:  ".result
  endif

  return result
endfunction

function! archivitor#util#SilentSystem(command, ...)
  let command = a:command

  if a:0 > 0
    " there are arguments, prepare them for the shell
    for args in a:000
      if type(args) == type({})
        " special case, the keys are flags, the values should be escaped
        for [flag, values] in items(args)
          if type(values) != type([])
            " work around type issues
            let new_values = [values]
            unlet values
            let values = new_values
          endif
          let command .= ' '.flag.' '.join(map(copy(values), 'shellescape(v:val)'), ' ')
          unlet values
        endfor
      else
        if type(args) != type([])
          " work around type issues
          let new_args = [args]
          unlet args
          let args = new_args
        endif

        let command .= ' '.join(map(copy(args), 'shellescape(v:val)'), ' ')
      endif

      unlet args
    endfor
  endif

  return system(command)
endfunction

function! archivitor#util#Group(list, batch_size)
  let batches = []
  let current_batch = []

  for item in a:list
    if len(current_batch) == a:batch_size
      call add(batches, current_batch)
      let current_batch = []
    endif

    call add(current_batch, item)
  endfor

  if len(current_batch) > 0
    call add(batches, current_batch)
  endif

  return batches
endfunction
