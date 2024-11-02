" autoload/vim_restman.vim

" --- Global Variables ---
let s:original_winid = 0
let s:original_bufnr = 0
let s:restman_winid = 0
let s:restman_bufnr = 0

" --- Main Function ---
function! vim_restman#Main()
    echom "vim_restman#Main() called"
    
    if !s:IsRestFile()
        echom "Not a .rest file, exiting"
        return
    endif

    call s:SaveOriginalState()

    let l:parsed_data = s:ParseCurrentFile()
    let l:request_index = s:GetRequestIndexFromCursor(l:parsed_data)
    let l:curl_command = s:BuildCurlCommand(l:parsed_data, l:request_index)
    let l:output = s:ExecuteCurlCommand(l:curl_command)

    call s:CreateRestManWindow()
    call s:PopulateRestManBuffer(l:parsed_data, l:curl_command, l:output, l:request_index)
    
    call s:ReturnToOriginalWindow()
    echom "Returned to original window"
endfunction

" --- File Validation ---
function! s:IsRestFile()
    let l:current_file = expand('%:p')
    let l:file_extension = fnamemodify(l:current_file, ':e')
    echom "Current file: " . l:current_file
    echom "File extension: " . l:file_extension
    return l:file_extension ==# 'rest'
endfunction

function! s:ParseCurrentFile()
    let l:captured_text = s:CaptureBetweenDelimiters('#Globals Start', '#Requests End')
    return s:ParseCapturedText(l:captured_text)
endfunction

function! s:CaptureBetweenDelimiters(start_delimiter, end_delimiter)
    let l:start_line = search(a:start_delimiter, 'n')
    let l:end_line = search(a:end_delimiter, 'n')
    return getline(l:start_line, l:end_line)
endfunction

function! s:GetRequestIndexFromCursor(parsed_data)
    let l:cursor_line = line('.')
    let l:request_index = 0
    let l:start_line = search('^#Requests Start', 'n')
    let l:end_line = search('^#Requests End', 'n')
    
    for i in range(len(a:parsed_data.requests))
        let l:request_start = search('^\s*--\s*$', 'n', l:end_line)
        let l:request_end = search('^\s*--\s*$', 'n', l:end_line)
        if l:cursor_line >= l:request_start && l:cursor_line <= l:request_end
            let l:request_index = i
            break
        endif
    endfor
    
    return l:request_index
endfunction

" --- Window and Buffer Management ---
function! s:SaveOriginalState()
    let s:original_winid = win_getid()
    let s:original_bufnr = bufnr('%')
    echom "Original window ID: " . s:original_winid
    echom "Original buffer number: " . s:original_bufnr
endfunction

function! s:ReturnToOriginalWindow()
    if win_gotoid(s:original_winid)
        echom "Returned to original window"
    else
        echom "Failed to return to original window"
    endif
endfunction

function! s:CreateRestManWindow()
    vsplit
    enew
    setlocal buftype=nofile
    setlocal bufhidden=hide
    setlocal noswapfile
    file RestMan
    let s:restman_bufnr = bufnr('%')
    echom "RestMan window ID: " . win_getid()
    echom "RestMan buffer number: " . s:restman_bufnr
endfunction

" --- Text Capture and Parsing ---
function! s:ParseCapturedText(captured_text)
    echom "s:ParseCapturedText() called"
    let l:parsed_data = {
        \ 'globals': {},
        \ 'requests': []
    \ }
    let l:current_section = ''
    let l:current_key = ''
    let l:current_request = {}

    for line in a:captured_text
        let l:trimmed_line = trim(line)
        if empty(l:trimmed_line)
            continue
        endif

        if l:trimmed_line =~ '^#Globals Start'
            let l:current_section = 'globals'
        elseif l:trimmed_line =~ '^#Requests Start'
            let l:current_section = 'requests'
        elseif l:trimmed_line =~ '^#'
            continue
        elseif l:current_section == 'globals'
            if l:trimmed_line =~ '^@'
                let l:current_key = l:trimmed_line[1:]
                let l:parsed_data.globals[l:current_key] = ''
            else
                let l:parsed_data.globals[l:current_key] .= (empty(l:parsed_data.globals[l:current_key]) ? '' : ' ') . l:trimmed_line
            endif
        elseif l:current_section == 'requests'
            if l:trimmed_line == '--'
                if !empty(l:current_request)
                    call add(l:parsed_data.requests, l:current_request)
                    let l:current_request = {}
                endif
            elseif l:trimmed_line =~ '^\(GET\|POST\|PUT\|DELETE\|PATCH\)'
                let [l:method, l:endpoint] = split(l:trimmed_line, ' ')
                let l:current_request = {'method': l:method, 'endpoint': l:endpoint, 'body': ''}
            elseif !empty(l:current_request)
                let l:current_request.body .= l:trimmed_line . "\n"
            endif
        endif
    endfor

    if !empty(l:current_request)
        call add(l:parsed_data.requests, l:current_request)
    endif

    for key in keys(l:parsed_data.globals)
        let l:parsed_data.globals[key] = trim(l:parsed_data.globals[key])
    endfor

    echom "Parsed data: " . string(l:parsed_data)
    return l:parsed_data
endfunction

" --- Curl Command Building and Execution ---
function! s:BuildCurlCommand(parsed_data, request_index)
    echom "s:BuildCurlCommand() called"
    
    let l:base_url = trim(get(a:parsed_data.globals, 'base_url', ''))
    let l:headers = get(a:parsed_data.globals, 'headers', '')
    let l:variables = get(a:parsed_data.globals, 'variables', '')
    let l:capture = get(a:parsed_data.globals, 'capture', '')

    let l:variables_dict = {}
    for var_line in split(l:variables, ' ')
        let l:parts = split(var_line, '=')
        if len(l:parts) == 2
            let [var_name, var_value] = l:parts
            if var_value =~ '^\$'
                let l:variables_dict[var_name] = eval('$' . var_value[1:])
            else
                let l:variables_dict[var_name] = var_value
            endif
        endif
    endfor

    let l:curl_command = 'curl -s'

    if len(a:parsed_data.requests) > a:request_index
        let l:request = a:parsed_data.requests[a:request_index]
        let l:method = get(l:request, 'method', 'GET')
        let l:endpoint = get(l:request, 'endpoint', '')
        let l:url = l:base_url . l:endpoint

        let l:curl_command .= ' -X ' . l:method
        let l:curl_command .= ' "' . l:url . '"'
    else
        echom "Error: No request found at index " . a:request_index
        return ''
    endif

    for header_line in split(l:headers, "\n")
        let l:trimmed_header = trim(header_line)
        if !empty(l:trimmed_header)
            let l:curl_command .= ' -H "' . l:trimmed_header . '"'
        endif
    endfor

    if l:method =~ '\v^(POST|PUT|PATCH)$' && has_key(l:request, 'body')
        let l:body = l:request.body
        for [var_name, var_value] in items(l:variables_dict)
            let l:body = substitute(l:body, ':' . var_name, var_value, 'g')
        endfor
        let l:body = substitute(l:body, '\n', '', 'g')
        let l:curl_command .= " --data '" . escape(trim(l:body), "'") . "'"
    endif

    echom "Built curl command: " . l:curl_command
    return l:curl_command
endfunction

function! s:ExecuteCurlCommand(curl_command)
    echom "s:ExecuteCurlCommand() called"
    let l:output = system(a:curl_command)
    let l:status = v:shell_error
    if l:status != 0
        let l:output = "Error executing curl command. Status: " . l:status . "\nOutput: " . l:output
    endif
    return l:output
endfunction

" --- Buffer Population ---
function! s:PopulateRestManBuffer(parsed_data, curl_command, output, request_index)
    echom "s:PopulateRestManBuffer() called"
    let l:content = "=== Globals ===\n\n"
    for [key, value] in items(a:parsed_data.globals)
        let l:content .= key . ": " . value . "\n"
    endfor
    let l:content .= "\n=== Requests ===\n"
    if len(a:parsed_data.requests) > a:request_index
        let l:request = a:parsed_data.requests[a:request_index]
        let l:content .= "Method: " . get(l:request, 'method', '') . "\n"
        let l:content .= "Endpoint: " . get(l:request, 'endpoint', '') . "\n"
        if has_key(l:request, 'body')
            let l:content .= "Body:\n" . l:request.body . "\n"
        endif
    else
        let l:content .= "No request found at index " . a:request_index . "\n"
    endif
    let l:content .= "\n=== Curl Command ===\n" . a:curl_command . "\n"
    let l:content .= "\n=== Curl Output ===\n" . a:output
    
    execute 'buffer ' . s:restman_bufnr
    setlocal modifiable
    %delete _
    call setline(1, split(l:content, "\n"))
    setlocal nomodifiable
endfunction

" --- Logging ---
function! s:LogInitialState()
    echom "Current window layout: " . s:GetWindowLayout()
    echom "Current buffer list: " . s:GetBufferList()
endfunction

function! s:LogFinalState()
    echom "Final window layout: " . s:GetWindowLayout()
    echom "Final buffer list: " . s:GetBufferList()
endfunction

" --- Helper Functions ---
function! s:GetWindowLayout()
    let l:layout = ""
    for i in range(1, winnr('$'))
        let l:bufname = bufname(winbufnr(i))
        let l:winid = win_getid(i)
        let l:layout .= "Win" . i . " (ID:" . l:winid . "):" . l:bufname . " | "
    endfor
    return l:layout
endfunction

function! s:GetBufferList()
    let l:buflist = ""
    for i in range(1, bufnr('$'))
        if buflisted(i)
            let l:buflist .= "Buf" . i . ":" . bufname(i) . " | "
        endif
    endfor
    return l:buflist
endfunction

" --- JSON Processing (placeholder for jq integration) ---
function! s:ProcessJsonWithJq(json, filter)
    echom "Processing JSON with jq filter: " . a:filter
    return "Processed JSON result"
endfunction

