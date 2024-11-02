if exists("g:loaded_vim_restman")
    finish
endif
let g:loaded_vim_restman = 1

function! s:CaptureAndPrintText()
    " Save the current cursor position
    let l:cur_pos = getcurpos()
    
    " Search backwards for the start delimiter
    let l:start_line = search('^--$', 'bnW')
    if l:start_line == 0
        echo "No start delimiter found"
        return
    endif

    " Search forwards for the end delimiter
    let l:end_line = search('^--$', 'nW')
    if l:end_line == 0
        echo "No end delimiter found"
        return
    endif

    " Check if cursor is within the delimiters
    if l:cur_pos[1] <= l:start_line || l:cur_pos[1] >= l:end_line
        echo "Cursor not between delimiters"
        return
    endif

    " Capture the text between delimiters
    let l:captured_text = getline(l:start_line + 1, l:end_line - 1)
    
    " Join the lines and remove leading/trailing whitespace
    let l:captured_text = join(l:captured_text, "\n")
    let l:captured_text = trim(l:captured_text)

    " Print the captured text
    echo "Captured Text:"
    echo "----------------------------------------"
    echo l:captured_text
    echo "----------------------------------------"
endfunction

" Map Ctrl+j to the capture and print function
nnoremap <C-j> :call <SID>CaptureAndPrintText()<CR>

