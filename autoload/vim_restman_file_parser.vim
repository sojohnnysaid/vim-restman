" autoload/vim_restman_file_parser.vim

" Parse the current file to extract REST API definitions
" @return {dict} Parsed data structure
function! vim_restman_file_parser#ParseCurrentFile()
    call vim_restman_utils#LogDebug("vim_restman_file_parser#ParseCurrentFile() called")
    
    " Log current file and cursor position
    call vim_restman_utils#LogDebug("Current file: " . expand('%:p'))
    call vim_restman_utils#LogDebug("Cursor position: Line " . line('.') . ", Column " . col('.'))
    
    " Capture text between delimiters
    let l:captured_text = s:CaptureBetweenDelimiters('#Globals Start', '#Requests End')
    
    " Parse the captured text
    let l:parsed_data = s:ParseCapturedText(l:captured_text)
    
    " Log the parsed requests for debugging
    call vim_restman_utils#LogDebug("Parsed " . len(l:parsed_data.requests) . " requests")
    for i in range(len(l:parsed_data.requests))
        let l:req = l:parsed_data.requests[i]
        call vim_restman_utils#LogDebug("Request " . i . ": " . l:req.method . " " . l:req.endpoint)
    endfor
    
    return l:parsed_data
endfunction

" Capture text between two delimiters in the current file
" @param {string} start_delimiter - The starting delimiter
" @param {string} end_delimiter - The ending delimiter
" @return {list} List of captured lines
function! s:CaptureBetweenDelimiters(start_delimiter, end_delimiter)
    let l:start_line = search(a:start_delimiter, 'n')
    let l:end_line = search(a:end_delimiter, 'n')
    
    if l:start_line == 0 || l:end_line == 0
        call vim_restman_utils#LogWarning("Could not find delimiters: " . a:start_delimiter . " or " . a:end_delimiter)
        return []
    endif
    
    let l:captured_text = getline(l:start_line, l:end_line)
    call vim_restman_utils#LogDebug("Captured " . len(l:captured_text) . " lines between delimiters")
    return l:captured_text
endfunction



" Parse captured text into structured data
" @param {list} captured_text - List of text lines captured from file
" @return {dict} Structured data with globals and requests
function! s:ParseCapturedText(captured_text)
    call vim_restman_utils#LogDebug("s:ParseCapturedText() called")
    
    " If no text was captured, return empty structure
    if empty(a:captured_text)
        call vim_restman_utils#LogWarning("No text captured to parse")
        return {'globals': {}, 'requests': []}
    endif
    
    let l:parsed_data = {
        \ 'globals': {},
        \ 'requests': []
    \ }
    let l:current_section = ''
    let l:current_key = ''
    let l:current_request = {}

    call vim_restman_utils#LogDebug("Parsing captured text...")
    for line in a:captured_text
        let l:trimmed_line = trim(line)
        if empty(l:trimmed_line)
            continue
        endif

        " Handle section markers
        if l:trimmed_line =~ '^#Globals Start'
            let l:current_section = 'globals'
            call vim_restman_utils#LogDebug("Entering globals section")
        elseif l:trimmed_line =~ '^#Requests Start'
            let l:current_section = 'requests'
            call vim_restman_utils#LogDebug("Entering requests section")
        elseif l:trimmed_line =~ '^#'
            " Skip other comments
            continue
        elseif l:current_section == 'globals'
            " Process global section content
            call s:ProcessGlobalLine(l:trimmed_line, l:parsed_data, l:current_key)
            if l:trimmed_line =~ '^@'
                let l:current_key = l:trimmed_line[1:]
            endif
        elseif l:current_section == 'requests'
            " Process request section content
            let [l:current_request, l:add_request] = s:ProcessRequestLine(l:trimmed_line, l:current_request)
            if l:add_request && !empty(l:current_request)
                call add(l:parsed_data.requests, l:current_request)
                call vim_restman_utils#LogDebug("Added request: " . l:current_request.method . " " . l:current_request.endpoint)
                let l:current_request = {}
            endif
        endif
    endfor

    " Add the last request if not added yet
    if !empty(l:current_request)
        call add(l:parsed_data.requests, l:current_request)
        call vim_restman_utils#LogDebug("Added final request: " . l:current_request.method . " " . l:current_request.endpoint)
    endif

    " Clean up and finalize the data
    call s:FinalizeData(l:parsed_data)
    
    call vim_restman_utils#LogDebug("Parsed " . len(l:parsed_data.requests) . " requests with " . len(keys(l:parsed_data.globals)) . " global sections")
    return l:parsed_data
endfunction

" Process a line in the globals section
" @param {string} line - The line to process
" @param {dict} parsed_data - Reference to the parsed data structure
" @param {string} current_key - The current global key being processed
function! s:ProcessGlobalLine(line, parsed_data, current_key)
    if a:line =~ '^@'
        " This is a new global key
        let l:key = a:line[1:]
        let a:parsed_data.globals[l:key] = ''
        call vim_restman_utils#LogDebug("New global key: " . l:key)
    elseif !empty(a:current_key)
        " Add content to the current global key
        if a:current_key == 'variables'
            call vim_restman_utils#LogDebug("Variable: " . a:line)
        elseif a:current_key == 'capture'
            call vim_restman_utils#LogDebug("Capture: " . a:line)
            call vim_restman_capture_manager#DeclareCaptureVariable(trim(a:line))
        endif
        
        " Append the line to the current key's value
        let a:parsed_data.globals[a:current_key] .= (empty(a:parsed_data.globals[a:current_key]) ? '' : "\n") . a:line
    endif
endfunction

" Process a line in the requests section
" @param {string} line - The line to process
" @param {dict} current_request - The current request being built
" @return {list} [updated_request, add_request_flag]
function! s:ProcessRequestLine(line, current_request)
    let l:add_request = 0
    let l:current_request = a:current_request
    
    if a:line == '--'
        " Request delimiter - end of current request
        let l:add_request = 1
        call vim_restman_utils#LogDebug("Found request delimiter")
    elseif a:line =~ '^--\s*\(GET\|POST\|PUT\|DELETE\|PATCH\)'
        " Request method and endpoint prefixed with --
        let l:method_line = substitute(a:line, '^--\s*', '', '')
        let [l:method, l:endpoint] = split(l:method_line, ' ', 1)
        let l:current_request = {'method': l:method, 'endpoint': l:endpoint, 'headers': '', 'body': ''}
        call vim_restman_utils#LogDebug("New request with -- prefix: " . l:method . " " . l:endpoint)
    elseif a:line =~ '^\(GET\|POST\|PUT\|DELETE\|PATCH\)'
        " Request method and endpoint
        let [l:method, l:endpoint] = split(a:line, ' ', 1)
        let l:current_request = {'method': l:method, 'endpoint': l:endpoint, 'headers': '', 'body': ''}
        call vim_restman_utils#LogDebug("New request without prefix: " . l:method . " " . l:endpoint)
    elseif a:line =~ '^[A-Za-z-]\+:'
        " Request header
        let l:current_request.headers .= a:line . "\n"
        call vim_restman_utils#LogDebug("Added header: " . a:line)
    elseif !empty(l:current_request)
        " Request body
        let l:current_request.body .= a:line . "\n"
        call vim_restman_utils#LogDebug("Added to request body")
    endif
    
    return [l:current_request, l:add_request]
endfunction

" Finalize and clean up the parsed data
" @param {dict} parsed_data - The parsed data structure to finalize
function! s:FinalizeData(parsed_data)
    " Trim all global values
    for key in keys(a:parsed_data.globals)
        " Make sure we're working with a string
        if type(a:parsed_data.globals[key]) == v:t_string
            let a:parsed_data.globals[key] = trim(a:parsed_data.globals[key])
            call vim_restman_utils#LogDebug("Trimmed global key: " . key)
        endif
    endfor

    " Process variables section
    if has_key(a:parsed_data.globals, 'variables')
        " Convert variables section to dictionary format if it's a string
        if type(a:parsed_data.globals.variables) == v:t_string
            let l:variables_dict = s:ParseVariables(a:parsed_data.globals.variables)
            let a:parsed_data.globals.variables = l:variables_dict
            call vim_restman_utils#LogDebug("Processed " . len(l:variables_dict) . " variables")
        endif
    endif
    
    " Trim headers and body in all requests
    for request in a:parsed_data.requests
        if has_key(request, 'headers') && type(request.headers) == v:t_string
            let request.headers = trim(request.headers)
        endif
        if has_key(request, 'body') && type(request.body) == v:t_string
            let request.body = trim(request.body)
        endif
    endfor
endfunction



" Parse variables from a string into a dictionary
" @param {string} variables_string - The string containing variable definitions
" @return {dict} Dictionary of parsed variables
function! s:ParseVariables(variables_string)
    let l:variables_dict = {}
    for var_line in split(a:variables_string, "\n")
        let l:parts = split(var_line, '=')
        if len(l:parts) == 2
            let [var_name, var_value] = l:parts
            let var_name = trim(var_name)
            let var_value = trim(var_value)
            let l:variables_dict[var_name] = var_value
            call vim_restman_utils#LogDebug("Parsed variable: " . var_name . " = " . var_value)
        else
            call vim_restman_utils#LogWarning("Invalid variable format: " . var_line)
        endif
    endfor
    return l:variables_dict
endfunction