if exists("g:loaded_vim_restman")
    finish
endif
let g:loaded_vim_restman = 1

" Create a log file in the same directory as the script
let s:log_file = expand('<sfile>:p:h') . '/vim-restman.log'

function! s:Log(message)
    call writefile([strftime('%Y-%m-%d %H:%M:%S') . ': ' . a:message], s:log_file, 'a')
endfunction

function! s:CaptureAndPrintText()
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

    " Create a new split window for output
    new
    setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile nowrap
    call setline(1, "Captured Text:")
    call setline(2, "----------------------------------------")
    call setline(3, split(l:captured_text, "\n"))
    call setline(line('$') + 1, "----------------------------------------")
    
    call s:Log('Output displayed in new buffer')
endfunction

" Map Ctrl+j (lowercase) to the capture and print function
nnoremap <silent> <C-j> :call <SID>CaptureAndPrintText()<CR>

call s:Log('Plugin loaded')

