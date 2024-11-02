let s:log_buffer_name = 'vim-restman-log'

function! s:Log(message)
    let l:log_msg = strftime('%Y-%m-%d %H:%M:%S') . ': ' . a:message
    
    " Find or create the log buffer
    let l:buf_num = bufnr(s:log_buffer_name)
    if l:buf_num == -1
        execute 'botright new ' . s:log_buffer_name
        setlocal buftype=nofile bufhidden=hide noswapfile
    else
        let l:win_num = bufwinnr(l:buf_num)
        if l:win_num == -1
            execute 'botright split'
            execute l:buf_num . 'buffer'
        else
            execute l:win_num . 'wincmd w'
        endif
    endif
    
    " Append the log message
    call append(line('$'), l:log_msg)
    normal! G
    
    " Return to the previous window
    wincmd p
endfunction

function! vim_restman#CaptureAndPrintText()
    call s:Log('Ctrl+j pressed, function called')

    " Save the current cursor position
    let l:cur_pos = getcurpos()
    
    " Search backwards for the start delimiter
    let l:start_line = search('^--$', 'bnW')
    if l:start_line == 0
        call s:Log('No start delimiter found')
        echom "No start delimiter found"
        return
    endif

    " Search forwards for the end delimiter
    let l:end_line = search('^--$', 'nW')
    if l:end_line == 0
        call s:Log('No end delimiter found')
        echom "No end delimiter found"
        return
    endif

    " Check if cursor is within the delimiters
    if l:cur_pos[1] <= l:start_line || l:cur_pos[1] >= l:end_line
        call s:Log('Cursor not between delimiters')
        echom "Cursor not between delimiters"
        return
    endif

    " Capture the text between delimiters
    let l:captured_text = getline(l:start_line + 1, l:end_line - 1)
    
    " Join the lines and remove leading/trailing whitespace
    let l:captured_text = join(l:captured_text, "\n")
    let l:captured_text = trim(l:captured_text)

    call s:Log('Text captured successfully')

    " Log the captured text
    call s:Log('Captured Text:')
    call s:Log('----------------------------------------')
    for line in split(l:captured_text, "\n")
        call s:Log(line)
    endfor
    call s:Log('----------------------------------------')
    
    call s:Log('Output displayed in log buffer')
endfunction

