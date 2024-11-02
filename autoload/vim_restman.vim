" autoload/vim_restman.vim

" --- Global Variables ---
let s:original_winid = 0
let s:original_bufnr = 0
let s:restman_winid = 0
let s:restman_bufnr = 0

" --- Main Function ---
function! vim_restman#Main()
    echom "vim_restman#Main() called"
    
    if s:IsValidRestFile()
        call s:SaveOriginalState()
        call s:LogInitialState()
        let l:captured_text = s:CaptureBetweenDelimiters()
        let l:parsed_data = s:ParseCapturedText(l:captured_text)
        let l:curl_command = s:BuildCurlCommand(l:parsed_data)
        let l:curl_output = s:ExecuteCurlCommand(l:curl_command)
        call s:CreateRestManWindow()
        call s:PopulateRestManBuffer(l:parsed_data, l:curl_command, l:curl_output)
        call s:LogFinalState()
        call s:ReturnToOriginalWindow()
    endif
endfunction

" --- File Validation ---
function! s:IsValidRestFile()
    let l:current_file = expand('%:p')
    let l:file_extension = fnamemodify(l:current_file, ':e')
    echom "Current file: " . l:current_file
    echom "File extension: " . l:file_extension

    if l:file_extension != 'rest'
        echom "File extension is not .rest, exiting"
        echo "RestMan: This file is not a .rest file."
        return 0
    endif

    echom "File is a .rest file, proceeding"
    return 1
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
    echom "s:CreateRestManWindow() called"

    let l:restman_buf = bufnr('RestMan')
    if l:restman_buf != -1
        let l:restman_win = bufwinnr(l:restman_buf)
        if l:restman_win != -1
            execute l:restman_win . 'wincmd w'
        else
            execute 'vertical split'
            execute 'buffer ' . l:restman_buf
        endif
    else
        execute 'vertical split RestMan'
        setlocal buftype=nofile
        setlocal bufhidden=hide
        setlocal noswapfile
    endif

    let s:restman_winid = win_getid()
    let s:restman_bufnr = bufnr('%')
    echom "RestMan window ID: " . s:restman_winid
    echom "RestMan buffer number: " . s:restman_bufnr
    echom "Window layout after split: " . s:GetWindowLayout()
endfunction

" --- Text Capture and Parsing ---
function! s:CaptureBetweenDelimiters()
    echom "s:CaptureBetweenDelimiters() called"
    let l:current_line = line('.')
    let l:current_col = col('.')

    let l:start_line = search('^#Globals Start$', 'bnW')
    let l:end_line = search('^#Requests End$', 'nW')

    if l:start_line == 0 || l:end_line == 0 || l:current_line < l:start_line || l:current_line > l:end_line
        echom "Cursor not within valid section"
        return []
    endif

    let l:captured_text = getline(l:start_line, l:end_line)
    echom "Captured text: " . string(l:captured_text)

    call cursor(l:current_line, l:current_col)

    return l:captured_text
endfunction

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
            if l:trimmed_line =~ '^POST'
                if !empty(l:current_request)
                    call add(l:parsed_data.requests, l:current_request)
                endif
                let l:current_request = {'method': 'POST', 'endpoint': split(l:trimmed_line)[1], 'body': ''}
            elseif !empty(l:current_request)
                let l:current_request.body .= l:trimmed_line . "\n"
            endif
        endif
    endfor

    if !empty(l:current_request)
        call add(l:parsed_data.requests, l:current_request)
    endif

    " Trim trailing spaces from global values
    for key in keys(l:parsed_data.globals)
        let l:parsed_data.globals[key] = trim(l:parsed_data.globals[key])
    endfor

    echom "Parsed data: " . string(l:parsed_data)
    return l:parsed_data
endfunction


" --- Curl Command Building and Execution ---
function! s:BuildCurlCommand(parsed_data)
    echom "s:BuildCurlCommand() called"
    
    let l:base_url = trim(get(a:parsed_data.globals, 'base_url', ''))
    let l:headers = get(a:parsed_data.globals, 'headers', '')
    let l:variables = get(a:parsed_data.globals, 'variables', '')
    let l:capture = get(a:parsed_data.globals, 'capture', '')

    " Process environment variables
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

    " Start building the curl command
    let l:curl_command = 'curl -s'

    " Add method and URL
    if !empty(a:parsed_data.requests)
        let l:request = a:parsed_data.requests[0]
        let l:method = get(l:request, 'method', 'GET')
        let l:endpoint = get(l:request, 'endpoint', '')
        let l:url = l:base_url . l:endpoint

        let l:curl_command .= ' -X ' . l:method
        let l:curl_command .= ' "' . l:url . '"'
    else
        echom "Error: No request found in parsed data"
        return ''
    endif

    " Add headers
    for header_line in split(l:headers, "\n")
        let l:trimmed_header = trim(header_line)
        if !empty(l:trimmed_header)
            let l:curl_command .= ' -H "' . l:trimmed_header . '"'
        endif
    endfor

    " Add body for POST requests
    if l:method == 'POST' && has_key(l:request, 'body')
        let l:body = l:request.body
        " Replace variables in the body
        for [var_name, var_value] in items(l:variables_dict)
            let l:body = substitute(l:body, ':' . var_name, var_value, 'g')
        endfor
        let l:body = substitute(l:body, '\n', '', 'g')  " Remove newlines
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
    echom "Curl command output: " . l:output
    return l:output
endfunction



" --- Buffer Population ---
function! s:PopulateRestManBuffer(parsed_data, curl_command, curl_output)
    echom "s:PopulateRestManBuffer() called"
    echom "Current buffer: " . bufname('%')
    silent %delete _

    call append(0, "=== Globals ===")
    for [key, value] in items(a:parsed_data.globals)
        call append(line('$'), key . ": " . value)
    endfor

    call append(line('$'), "")
    call append(line('$'), "=== Requests ===")
    for request in a:parsed_data.requests
        call append(line('$'), "Method: " . request.method)
        call append(line('$'), "Endpoint: " . request.endpoint)
        call append(line('$'), "Body:")
        call append(line('$'), split(request.body, "\n"))
        call append(line('$'), "")
    endfor

    call append(line('$'), "=== Curl Command ===")
    call append(line('$'), a:curl_command)

    call append(line('$'), "")
    call append(line('$'), "=== Curl Output ===")
    call append(line('$'), split(a:curl_output, "\n"))

    normal! gg
    echom "Buffer populated with parsed data, curl command, and output"
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
    " This is a placeholder function for jq integration
    " In a real implementation, you would call jq here
    echom "Processing JSON with jq filter: " . a:filter
    return "Processed JSON result"
endfunction

