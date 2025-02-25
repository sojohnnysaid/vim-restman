" autoload/vim_restman_curl_builder.vim

" Build a curl command from request data
" @param {dict} parsed_data - The parsed data containing requests and globals
" @param {number} request_index - The index of the request to build
" @param {dict} variables - Dictionary of variables to substitute
" @return {string} The constructed curl command
function! vim_restman_curl_builder#BuildCurlCommand(parsed_data, request_index, variables)
    call vim_restman_utils#LogDebug("Building curl command for request " . a:request_index)
    
    let l:base_url = trim(get(a:parsed_data.globals, 'base_url', ''))
    let l:curl_command = 'curl -s'

    if len(a:parsed_data.requests) > a:request_index
        let l:request = a:parsed_data.requests[a:request_index]
        let l:method = get(l:request, 'method', 'GET')
        let l:endpoint = get(l:request, 'endpoint', '')
        let l:url = l:base_url . l:endpoint

        " Substitute variables in the URL
        let l:url = vim_restman_utils#SubstituteVariables(l:url, a:variables)

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
        call vim_restman_utils#LogError("No request found at index " . a:request_index)
        return ''
    endif

    call vim_restman_utils#LogDebug("Built curl command: " . l:curl_command)
    return l:curl_command
endfunction

" Add headers to curl command
" @param {string} headers - The headers string
" @param {dict} variables - Variables for substitution
" @return {string} Curl command headers part
function! s:AddHeaders(headers, variables)
    let l:curl_headers = ''
    for header in split(a:headers, "\n")
        let l:original_header = header
        let l:processed_header = vim_restman_utils#SubstituteVariables(header, a:variables)
        call vim_restman_utils#LogDebug("Processing header: " . l:original_header)
        
        if !empty(trim(l:processed_header)) && l:processed_header !~ ':$'
            let l:curl_headers .= ' -H "' . trim(l:processed_header) . '"'
            call vim_restman_utils#LogDebug("Added header: " . trim(l:processed_header))
        else
            call vim_restman_utils#LogDebug("Skipped header due to empty or incomplete: " . l:original_header)
        endif
    endfor
    return l:curl_headers
endfunction

" Add request body to curl command
" @param {string} method - HTTP method
" @param {dict} request - The request data
" @param {dict} variables - Variables for substitution
" @return {string} Curl command body part
function! s:AddRequestBody(method, request, variables)
    let l:curl_body = ''
    if a:method =~ '\v^(POST|PUT|PATCH)$' && has_key(a:request, 'body')
        let l:body = vim_restman_utils#SubstituteVariables(a:request.body, a:variables)
        
        " Preserve newlines in JSON bodies for better readability in the request
        if l:body =~ '^\s*{' || l:body =~ '^\s*\['
            let l:curl_body .= " --data '" . escape(trim(l:body), "'") . "'"
        else
            " For non-JSON bodies, remove newlines
            let l:body = substitute(l:body, '\n', '', 'g')
            let l:curl_body .= " --data '" . escape(trim(l:body), "'") . "'"
        endif
        
        call vim_restman_utils#LogDebug("Added request body")
    endif
    return l:curl_body
endfunction

" Execute a curl command and process the response
" @param {string} curl_command - The curl command to execute
" @return {list} [output, captures] - The command output and captured variables
function! vim_restman_curl_builder#ExecuteCurlCommand(curl_command)
    call vim_restman_utils#LogInfo("Executing curl command...")
    call vim_restman_utils#LogDebug("Command: " . a:curl_command)
    
    let l:output = system(a:curl_command)
    let l:status = v:shell_error
    
    if l:status != 0
        call vim_restman_utils#LogWarning("Curl command failed with status " . l:status)
        let l:output = "Error executing curl command. Status: " . l:status . "\nOutput: " . l:output
        let l:updated_captures = {}
    else
        call vim_restman_utils#LogDebug("Received response of length: " . strlen(l:output))
        
        " Try to format JSON response for better display
        let l:json_formatted = vim_restman_json#Format(l:output)
        
        " Use formatted JSON if successful, otherwise use raw response
        if l:json_formatted != l:output
            call vim_restman_utils#LogDebug("Formatted JSON response successfully")
            let l:output = l:json_formatted
        endif
        
        " Process the JSON response to update captured values
        let l:updated_captures = s:ProcessCaptures(l:output)
    endif
    
    return [l:output, l:updated_captures]
endfunction

" Process response captures for variables
" @param {string} response - The response data to process
" @return {dict} Dictionary of captured variables
function! s:ProcessCaptures(response)
    call vim_restman_utils#LogDebug("Processing response captures")
    let l:captures = {}
    let l:variables = vim_restman#GetVariables()
    
    " Capture variables from response
    for [var_name, var_info] in items(l:variables)
        " Only process variables that have 'set' = 0 or don't have 'set' key
        if !has_key(var_info, 'set') || !var_info.set
            " Check if var_name is in the format 'response.field'
            if var_name =~ '^response\.'
                let l:field = substitute(var_name, '^response\.', '', '')
                
                " Try to extract the value using jq if it's a valid JSON response
                if vim_restman_json#IsValidJson(a:response)
                    " Use jq to extract the value
                    let l:jq_filter = '.' . l:field
                    let l:value = vim_restman_json#Extract(a:response, l:jq_filter)
                    
                    " Remove surrounding quotes and parse if needed
                    let l:value = substitute(l:value, '^"\(.*\)"$', '\1', '')
                    let l:value = substitute(l:value, '\\n', "\n", 'g')
                    let l:value = substitute(l:value, '\\t', "\t", 'g')
                    
                    if !empty(l:value) && l:value != 'null'
                        let l:captures[var_name] = l:value
                        call vim_restman_utils#LogDebug("Captured " . var_name . " = " . l:value)
                    endif
                else
                    " Try with simple regex for non-JSON responses
                    call vim_restman_utils#LogDebug("Not valid JSON, trying regex pattern matching")
                    
                    " Extract value using regex pattern matching
                    let l:pattern = '"' . l:field . '"\s*:\s*\("[^"]*"\|[0-9]\+\)'
                    let l:match = matchstr(a:response, l:pattern)
                    
                    if !empty(l:match)
                        " Extract only the value part (after the colon)
                        let l:value = matchstr(l:match, ':\s*\zs\("[^"]*"\|[0-9]\+\)')
                        " Remove quotes from string values
                        let l:value = substitute(l:value, '^"\(.*\)"$', '\1', '')
                        let l:captures[var_name] = l:value
                        call vim_restman_utils#LogDebug("Captured " . var_name . " = " . l:value . " using regex")
                    endif
                endif
            endif
        endif
    endfor
    
    return l:captures
endfunction

" Format a curl command for display
" @param {string} curl_command - The curl command to format
" @return {string} The formatted curl command
function! vim_restman_curl_builder#FormatCurlCommand(curl_command)
    let l:formatted = substitute(a:curl_command, ' -', "\n  -", 'g')
    let l:formatted = substitute(l:formatted, '--data ', "\n  --data ", 'g')
    return l:formatted
endfunction