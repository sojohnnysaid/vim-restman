" autoload/vim_restman_curl_builder.vim

function! vim_restman_curl_builder#BuildCurlCommand(parsed_data, request_index)
    echom "vim_restman_curl_builder#BuildCurlCommand() called"
    
    let l:base_url = trim(get(a:parsed_data.globals, 'base_url', ''))
    let l:headers = get(a:parsed_data.globals, 'headers', '')
    let l:variables = get(a:parsed_data.globals, 'variables', '')
    let l:capture = get(a:parsed_data.globals, 'capture', '')

    let l:variables_dict = s:ParseVariables(l:variables)

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

    let l:curl_command .= s:AddHeaders(l:headers)
    let l:curl_command .= s:AddRequestBody(l:method, l:request, l:variables_dict)

    echom "Built curl command: " . l:curl_command
    return l:curl_command
endfunction

function! vim_restman_curl_builder#ExecuteCurlCommand(curl_command)
    echom "vim_restman_curl_builder#ExecuteCurlCommand() called"
    let l:output = system(a:curl_command)
    let l:status = v:shell_error
    if l:status != 0
        let l:output = "Error executing curl command. Status: " . l:status . "\nOutput: " . l:output
    endif
    return l:output
endfunction

function! s:ParseVariables(variables_string)
    let l:variables_dict = {}
    for var_line in split(a:variables_string, ' ')
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
    return l:variables_dict
endfunction

function! s:AddHeaders(headers)
    let l:curl_headers = ''
    for header_line in split(a:headers, "\n")
        let l:trimmed_header = trim(header_line)
        if !empty(l:trimmed_header)
            let l:curl_headers .= ' -H "' . l:trimmed_header . '"'
        endif
    endfor
    return l:curl_headers
endfunction

function! s:AddRequestBody(method, request, variables_dict)
    let l:curl_body = ''
    if a:method =~ '\v^(POST|PUT|PATCH)$' && has_key(a:request, 'body')
        let l:body = a:request.body
        for [var_name, var_value] in items(a:variables_dict)
            let l:body = substitute(l:body, ':' . var_name, var_value, 'g')
        endfor
        let l:body = substitute(l:body, '\n', '', 'g')
        let l:curl_body .= " --data '" . escape(trim(l:body), "'") . "'"
    endif
    return l:curl_body
endfunction

function! vim_restman_curl_builder#FormatCurlCommand(curl_command)
    let l:formatted = substitute(a:curl_command, ' -', "\n  -", 'g')
    let l:formatted = substitute(l:formatted, '--data ', "\n  --data ", 'g')
    return l:formatted
endfunction

