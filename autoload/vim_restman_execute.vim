" autoload/vim_restman_execute.vim
" Request execution for vim-restman

" Execute a HTTP request and show the results
" @param {dict} parsed_data - The parsed data containing requests and globals
" @param {number} request_index - The index of the request to execute
" @return {boolean} True if execution was successful
function! vim_restman_execute#ExecuteRequest(parsed_data, request_index)
    " Validate request index
    if a:request_index < 0 || a:request_index >= len(a:parsed_data.requests)
        call vim_restman_utils#LogError("Invalid request index: " . a:request_index)
        return 0
    endif
    
    " Get the request details
    let l:request = a:parsed_data.requests[a:request_index]
    call vim_restman_utils#LogInfo("Executing request: " . l:request.method . " " . l:request.endpoint)
    
    " Build the curl command
    let l:curl_command = vim_restman_curl_builder#BuildCurlCommand(a:parsed_data, a:request_index, vim_restman_store#GetAllVariables())
    call vim_restman_utils#LogDebug("Built curl command: " . l:curl_command)
    
    " Save original state
    let l:original_window = winnr()
    
    " Try to create or reuse the results window
    try
        " Check if we already have a RestMan window open
        let l:found_window = 0
        for winid in range(1, winnr('$'))
            let l:bufname = bufname(winbufnr(winid))
            if l:bufname =~ 'RestMan'
                execute winid . 'wincmd w'
                let l:found_window = 1
                break
            endif
        endfor
        
        " If no window found, create a new one
        if !l:found_window
            execute 'vsplit RestMan_Results'
        endif
    catch
        " Fallback: just create a new split
        execute 'vsplit RestMan_Results'
    endtry
    
    " Configure the buffer
    setlocal buftype=nofile
    setlocal bufhidden=hide
    setlocal noswapfile
    setlocal modifiable
    
    " Clear buffer content
    silent! execute '1,$delete _'
    
    " Execute the curl command with header capturing
    let [l:output, l:headers, l:exit_status] = s:ExecuteCurlWithHeaders(l:curl_command)
    
    " Process the response to capture variables
    let l:captures = vim_restman_store#ProcessCaptures(l:output)
    
    " Generate content in markdown format
    let l:content = []
    
    " Add request info
    call add(l:content, "# Request: " . l:request.method . " " . l:request.endpoint)
    call add(l:content, "# Executed at: " . strftime("%c"))
    call add(l:content, "")
    
    " Add request details
    call add(l:content, "## Request Details")
    call add(l:content, "")
    call add(l:content, "### HTTP Method")
    call add(l:content, l:request.method)
    call add(l:content, "")
    call add(l:content, "### URL")
    call add(l:content, l:request.endpoint)
    call add(l:content, "")
    
    " Add headers
    if has_key(l:request, 'headers') && !empty(l:request.headers)
        call add(l:content, "### Headers")
        for header_line in split(l:request.headers, "\n")
            call add(l:content, header_line)
        endfor
        call add(l:content, "")
    endif
    
    " Add curl command
    call add(l:content, "### Generated Curl Command")
    let l:formatted_curl = vim_restman_curl_builder#FormatCurlCommand(l:curl_command)
    for curl_line in split(l:formatted_curl, "\n")
        call add(l:content, curl_line)
    endfor
    call add(l:content, "")
    
    " Add response section
    call add(l:content, "## Response")
    call add(l:content, "")
    
    " Add response headers
    if !empty(l:headers)
        call add(l:content, "### Response Headers")
        for header_line in split(l:headers, "\n")
            call add(l:content, header_line)
        endfor
        call add(l:content, "")
    endif
    
    " Add response body
    call add(l:content, "### Response Body")
    for response_line in split(l:output, "\n")
        call add(l:content, response_line)
    endfor
    call add(l:content, "")
    
    " Add captured variables
    if !empty(l:captures)
        call add(l:content, "## Captured Variables")
        call add(l:content, "")
        for [var_name, var_value] in items(l:captures)
            call add(l:content, var_name . ": " . var_value)
        endfor
    endif
    
    " Set the buffer content
    call setline(1, l:content)
    
    " Set up syntax highlighting
    setlocal ft=markdown
    
    " Make buffer not modifiable
    setlocal nomodifiable
    
    " Add to history
    call vim_restman_store#AddToHistory(l:request, l:output, "RestMan")
    
    " Return to original window
    execute l:original_window . 'wincmd w'
    
    return 1
endfunction

" Execute curl command and capture headers separately
" @param {string} curl_command - The curl command to execute
" @return {list} [response_body, response_headers, exit_status]
function! s:ExecuteCurlWithHeaders(curl_command)
    " Add options to output headers to stdout
    let l:cmd = a:curl_command . ' -i'
    
    " Execute the command
    let l:output = system(l:cmd)
    let l:exit_status = v:shell_error
    
    " Split headers and body
    let l:parts = s:SplitHeadersAndBody(l:output)
    let l:headers = l:parts[0]
    let l:body = l:parts[1]
    
    " Log results
    call vim_restman_utils#LogDebug("curl exit status: " . l:exit_status)
    call vim_restman_utils#LogDebug("Headers length: " . strlen(l:headers))
    call vim_restman_utils#LogDebug("Body length: " . strlen(l:body))
    
    return [l:body, l:headers, l:exit_status]
endfunction

" Split response into headers and body
" @param {string} response - The response to split
" @return {list} [headers, body]
function! s:SplitHeadersAndBody(response)
    let l:headers = ''
    let l:body = ''
    
    " Find the double newline that separates headers and body
    let l:separator_pos = match(a:response, "\r\n\r\n")
    if l:separator_pos == -1
        let l:separator_pos = match(a:response, "\n\n")
    endif
    
    if l:separator_pos != -1
        let l:headers = strpart(a:response, 0, l:separator_pos)
        let l:body = strpart(a:response, l:separator_pos + 4)
    else
        " No clear separation, assume it's all body
        let l:body = a:response
    endif
    
    return [l:headers, l:body]
endfunction