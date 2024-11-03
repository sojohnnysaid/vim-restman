" autoload/vim_restman_curl_builder.vim

function! vim_restman_curl_builder#BuildCurlCommand(parsed_data, request_index, variables)
    echom "vim_restman_curl_builder#BuildCurlCommand() called"
    
    let l:base_url = trim(get(a:parsed_data.globals, 'base_url', ''))
    let l:curl_command = 'curl -s'

    if len(a:parsed_data.requests) > a:request_index
        let l:request = a:parsed_data.requests[a:request_index]
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
        echom "Error: No request found at index " . a:request_index
        return ''
    endif

    echom "Built curl command: " . l:curl_command
    return l:curl_command
endfunction



function! s:AddHeaders(headers, variables)
    let l:curl_headers = ''
    for header in split(a:headers, "\n")
        let l:original_header = header
        let l:processed_header = s:SubstituteVariables(header, a:variables)
        echom "Original header: " . l:original_header
        echom "Processed header: " . l:processed_header
        if !empty(trim(l:processed_header)) && l:processed_header !~ ':$' && l:processed_header ==# l:original_header
            let l:curl_headers .= ' -H "' . trim(l:processed_header) . '"'
            echom "Added header: " . trim(l:processed_header)
        else
            echom "Skipped header due to unset variable: " . l:original_header
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
    for [var_name, var_info] in items(a:variables)
        echom "Checking variable: " . var_name . ", set: " . var_info.set . ", value: " . var_info.value
        if var_info.set
            let l:result = substitute(l:result, ':' . var_name, var_info.value, 'g')
        else
            echom "Skipping unset variable: " . var_name
        endif
    endfor
    echom "After substitution: " . l:result
    return l:result
endfunction




function! vim_restman_curl_builder#ExecuteCurlCommand(curl_command)
    echom "vim_restman_curl_builder#ExecuteCurlCommand() called"
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
            if var_value =~ '^\$'
                let l:variables_dict[trim(var_name)] = eval('$' . var_value[1:])
            else
                let l:variables_dict[trim(var_name)] = trim(var_value)
            endif
        endif
    endfor
    return l:variables_dict
endfunction

function! vim_restman_curl_builder#FormatCurlCommand(curl_command)
    let l:formatted = substitute(a:curl_command, ' -', "\n  -", 'g')
    let l:formatted = substitute(l:formatted, '--data ', "\n  --data ", 'g')
    return l:formatted
endfunction

