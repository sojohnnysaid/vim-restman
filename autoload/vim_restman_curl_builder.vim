" autoload/vim_restman_curl_builder.vim

" autoload/vim_restman_curl_builder.vim

function! vim_restman_curl_builder#BuildCurlCommand(parsed_data, variables)
    " echom "vim_restman_curl_builder#BuildCurlCommand() called"
    
    let l:base_url = trim(get(a:parsed_data.globals, 'base_url', ''))
    let l:curl_command = 'curl -s'

    if !empty(a:parsed_data.requests)
        let l:request = a:parsed_data.requests[0]  " Always use the first (and only) request
        let l:method = get(l:request, 'method', 'GET')
        let l:endpoint = get(l:request, 'endpoint', '')
        let l:url = l:base_url . l:endpoint

        " Substitute variables in the URL
        let l:url = s:SubstituteVariables(l:url, a:variables)

        let l:curl_command .= ' -X ' . l:method
        let l:curl_command .= ' "' . l:url . '"'

        " Add headers
        let l:headers = get(a:parsed_data.globals, 'headers', '')
        let l:curl_command .= s:AddHeaders(l:headers, a:variables)

        " Add request-specific headers
        if has_key(l:request, 'headers')
            let l:curl_command .= s:AddHeaders(l:request.headers, a:variables)
        endif

        " Add request body
        let l:curl_command .= s:AddRequestBody(l:method, l:request, a:variables)
    else
        " echom "Error: No request found in parsed data"
        return ''
    endif

    " echom "Built curl command: " . l:curl_command
    return l:curl_command
endfunction




function! s:AddHeaders(headers, variables)
    let l:curl_headers = ''
    for header in split(a:headers, "\n")
        let l:original_header = header
        let l:processed_header = s:SubstituteVariables(header, a:variables)
        " echom "Original header: " . l:original_header
        " echom "Processed header: " . l:processed_header
        
        " Check if the processed header still contains any ':variable' placeholders
        if l:processed_header !~ ':[a-zA-Z0-9_]\+'
            if !empty(trim(l:processed_header)) && l:processed_header =~ ':'
                let l:header_parts = split(l:processed_header, ':', 1)
                if len(l:header_parts) >= 2
                    let l:header_name = l:header_parts[0]
                    let l:header_value = join(l:header_parts[1:], ':')
                    if !empty(trim(l:header_value))
                        let l:curl_headers .= ' -H "' . trim(l:header_name) . ': ' . trim(l:header_value) . '"'
                        " echom "Added header: " . trim(l:header_name) . ': ' . trim(l:header_value)
                    else
                        " echom "Skipped header due to empty value: " . l:original_header
                    endif
                else
                    " echom "Skipped header due to invalid format: " . l:original_header
                endif
            else
                " echom "Skipped header due to invalid format: " . l:original_header
            endif
        else
            " echom "Skipped header due to unset variable: " . l:original_header
        endif
    endfor
    return l:curl_headers
endfunction




function! s:AddRequestBody(method, request, variables)
    let l:curl_body = ''
    if a:method =~ '\v^(POST|PUT|PATCH)$' && has_key(a:request, 'body')
        let l:body = s:SubstituteVariables(a:request.body, a:variables)
        let l:body = substitute(l:body, '\n', '', 'g')
        let l:curl_body .= " --data '" . escape(trim(l:body), "'") . "'"
    endif
    return l:curl_body
endfunction




function! s:SubstituteVariables(text, variables)
    let l:result = a:text
    " echom "Original text: " . l:result
    for [var_name, var_info] in items(a:variables)
        " echom "Checking variable: " . var_name . ", set: " . var_info.set . ", value: " . var_info.value
        if var_info.set && !empty(var_info.value)
            let l:result = substitute(l:result, ':' . var_name, var_info.value, 'g')
            " echom "Substituted :". var_name ." with " . var_info.value
        else
            " Check if it's a captured variable
            let captured_value = vim_restman_capture_manager#GetCapturedValue(var_name)
            if !empty(captured_value)
                let l:result = substitute(l:result, ':' . var_name, captured_value, 'g')
                " echom "Using captured value for " . var_name . ": " . captured_value
            else
                " echom "Variable not set or captured: " . var_name
            endif
        endif
    endfor
    " echom "After substitution: " . l:result
    return l:result
endfunction




function! vim_restman_curl_builder#ExecuteCurlCommand(curl_command)
    " echom "vim_restman_curl_builder#ExecuteCurlCommand() called"
    let l:output = system(a:curl_command)
    let l:status = v:shell_error
    if l:status != 0
        let l:output = "Error executing curl command. Status: " . l:status . "\nOutput: " . l:output
        let l:updated_captures = {}
    else
        " Process the JSON response to update captured values
        let l:updated_captures = vim_restman_capture_manager#ProcessJsonResponse(l:output)
    endif
    return [l:output, l:updated_captures]
endfunction





function! s:ParseVariables(variables_string)
    let l:variables_dict = {}
    for var_line in split(a:variables_string, "\n")
        let l:parts = split(var_line, '=')
        if len(l:parts) == 2
            let [var_name, var_value] = l:parts
            let l:variables_dict[trim(var_name)] = trim(var_value)
            " echom "Parsed variable: " . trim(var_name) . " = " . trim(var_value)
        else
            " echom "Invalid variable format: " . var_line
        endif
    endfor
    return l:variables_dict
endfunction





function! vim_restman_curl_builder#FormatCurlCommand(curl_command)
    let l:formatted = substitute(a:curl_command, ' -', "\n  -", 'g')
    let l:formatted = substitute(l:formatted, '--data ', "\n  --data ", 'g')
    return l:formatted
endfunction

