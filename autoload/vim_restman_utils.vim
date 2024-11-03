" autoload/vim_restman_utils.vim

" --- File Validation ---
function! vim_restman_utils#IsRestFile()
    let l:current_file = expand('%:p')
    let l:file_extension = fnamemodify(l:current_file, ':e')
    echom "Current file: " . l:current_file
    echom "File extension: " . l:file_extension
    return l:file_extension ==# 'rest'
endfunction

" --- Request Index ---
function! vim_restman_utils#GetRequestIndexFromCursor(parsed_data)
    let l:cursor_line = line('.')
    let l:request_index = -1
    let l:start_line = search('^#Requests Start', 'n')
    let l:end_line = search('^#Requests End', 'n')
    
    let l:request_start = l:start_line
    for i in range(len(a:parsed_data.requests))
        let l:request_end = search('^\s*--\s*$', 'n', l:end_line)
        if l:cursor_line >= l:request_start && l:cursor_line <= l:request_end
            let l:request_index = i
            break
        endif
        let l:request_start = l:request_end + 1
    endfor
    
    return l:request_index
endfunction



" --- Logging ---
function! vim_restman_utils#LogInitialState()
    echom "Current window layout: " . vim_restman_utils#GetWindowLayout()
    echom "Current buffer list: " . vim_restman_utils#GetBufferList()
endfunction

function! vim_restman_utils#LogFinalState()
    echom "Final window layout: " . vim_restman_utils#GetWindowLayout()
    echom "Final buffer list: " . vim_restman_utils#GetBufferList()
endfunction

" --- Window and Buffer Info ---
function! vim_restman_utils#GetWindowLayout()
    let l:layout = ""
    for i in range(1, winnr('$'))
        let l:bufname = bufname(winbufnr(i))
        let l:winid = win_getid(i)
        let l:layout .= "Win" . i . " (ID:" . l:winid . "):" . l:bufname . " | "
    endfor
    return l:layout
endfunction

function! vim_restman_utils#GetBufferList()
    let l:buflist = ""
    for i in range(1, bufnr('$'))
        if buflisted(i)
            let l:buflist .= "Buf" . i . ":" . bufname(i) . " | "
        endif
    endfor
    return l:buflist
endfunction

" --- JSON Processing ---
function! vim_restman_utils#ProcessJsonWithJq(json, filter)
    echom "Processing JSON with jq filter: " . a:filter
    " TODO: Implement actual jq integration
    return "Processed JSON result"
endfunction

" --- String Manipulation ---
function! vim_restman_utils#TrimString(str)
    return substitute(a:str, '^\s*\(.\{-}\)\s*$', '\1', '')
endfunction

" --- Error Handling ---
function! vim_restman_utils#LogError(message)
    echohl ErrorMsg
    echom "RestMan Error: " . a:message
    echohl None
endfunction

" --- Variable Substitution ---
function! vim_restman_utils#SubstituteVariables(text, variables)
    let l:result = a:text
    for [var_name, var_value] in items(a:variables)
        let l:result = substitute(l:result, ':' . var_name, var_value, 'g')
    endfor
    return l:result
endfunction

" --- Curl Command Escaping ---
function! vim_restman_utils#EscapeCurlCommand(str)
    return escape(a:str, '"')
endfunction

