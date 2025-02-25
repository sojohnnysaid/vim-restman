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
    
    " Create a new buffer for this request
    let l:buffer_info = vim_restman_buffer#CreateResultBuffer(l:request, l:request.method, l:request.endpoint)
    
    " Execute the curl command with header capturing
    let [l:output, l:headers, l:exit_status, l:status_code, l:execution_time] = s:ExecuteCurlWithHeaders(l:curl_command)
    
    " Process the response to capture variables
    let l:captures = vim_restman_store#ProcessCaptures(l:output)
    
    " Populate the result buffer
    call vim_restman_buffer#PopulateResultBuffer(
                \ l:buffer_info, 
                \ l:request, 
                \ l:curl_command, 
                \ l:output, 
                \ l:captures, 
                \ l:headers)
    
    " Update the buffer with execution metadata if verbose output is enabled
    if get(g:, 'vim_restman_verbose_output', 0)
        call vim_restman_buffer#AddExecutionMetadata(
                    \ l:buffer_info, 
                    \ l:status_code, 
                    \ l:execution_time, 
                    \ l:exit_status)
    endif
    
    " Add to history
    call vim_restman_store#AddToHistory(l:request, l:output, "RestMan")
    
    return 1
endfunction

" Execute curl command and capture headers separately
" @param {string} curl_command - The curl command to execute
" @return {list} [response_body, response_headers, exit_status]
function! s:ExecuteCurlWithHeaders(curl_command)
    " Add options to output headers to stdout
    let l:cmd = a:curl_command . ' -i'
    
    " Add verbose flag if enabled
    if get(g:, 'vim_restman_verbose_output', 0)
        let l:cmd .= ' -v'
    endif
    
    " Execute the command
    let l:start_time = reltime()
    let l:output = system(l:cmd)
    let l:execution_time = reltimefloat(reltime(l:start_time)) * 1000  " in milliseconds
    let l:exit_status = v:shell_error
    
    " Split headers and body
    let l:parts = s:SplitHeadersAndBody(l:output)
    let l:headers = l:parts[0]
    let l:body = l:parts[1]
    
    " Extract status code from headers if available
    let l:status_code = s:ExtractStatusCode(l:headers)
    
    " Log results
    call vim_restman_utils#LogDebug("curl exit status: " . l:exit_status)
    call vim_restman_utils#LogDebug("Headers length: " . strlen(l:headers))
    call vim_restman_utils#LogDebug("Body length: " . strlen(l:body))
    call vim_restman_utils#LogDebug("Execution time: " . l:execution_time . " ms")
    
    return [l:body, l:headers, l:exit_status, l:status_code, l:execution_time]
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

" Extract status code from response headers
" @param {string} headers - The headers to parse
" @return {string} The status code or empty string if not found
function! s:ExtractStatusCode(headers)
    let l:status_code = ''
    let l:header_lines = split(a:headers, "\n")
    
    if len(l:header_lines) > 0
        " Status code is in the first line of headers: "HTTP/1.1 200 OK"
        let l:status_line = l:header_lines[0]
        let l:matches = matchlist(l:status_line, 'HTTP/\d\.\d\s\+\(\d\+\)')
        
        if len(l:matches) > 1
            let l:status_code = l:matches[1]
        endif
    endif
    
    return l:status_code
endfunction