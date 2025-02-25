" autoload/vim_restman_utils.vim

" --- File Validation ---
" Check if current file is a .rest file
" @return {boolean} True if current file has .rest extension
function! vim_restman_utils#IsRestFile()
    let l:current_file = expand('%:p')
    let l:file_extension = fnamemodify(l:current_file, ':e')
    call vim_restman_utils#LogDebug("Current file: " . l:current_file)
    call vim_restman_utils#LogDebug("File extension: " . l:file_extension)
    return l:file_extension ==# 'rest'
endfunction

" --- Request Index ---
" Get the index of the request where the cursor is currently positioned
" @param {dict} parsed_data - The parsed data containing requests
" @return {number} The index of the request or -1 if not found
function! vim_restman_utils#GetRequestIndexFromCursor(parsed_data)
    " Get the current cursor line
    let l:cursor_line = line('.')
    
    " Default to invalid index
    let l:request_index = -1
    
    " Find the requests section boundaries
    let l:start_line = search('^#Requests Start', 'n')
    let l:end_line = search('^#Requests End', 'n')
    
    " Log the basic info
    call vim_restman_utils#LogDebug("Cursor at line: " . l:cursor_line)
    call vim_restman_utils#LogDebug("Requests section: lines " . l:start_line . "-" . l:end_line)
    
    " Check if cursor is in the requests section
    if l:cursor_line < l:start_line || l:cursor_line > l:end_line
        call vim_restman_utils#LogWarning("Cursor is outside the requests section")
        return -1
    endif
    
    " Count how many request blocks we have
    let l:num_requests = len(a:parsed_data.requests)
    call vim_restman_utils#LogDebug("Found " . l:num_requests . " parsed requests")
    
    " Manual approach: Get all the lines for each method to avoid regex issues
    let l:lines = []
    let l:current_line = l:start_line
    
    " Loop through each line in the request section
    while l:current_line <= l:end_line
        let l:line_text = getline(l:current_line)
        " Look for lines that start with a method name (GET, POST, etc.)
        for i in range(l:num_requests)
            let l:req = a:parsed_data.requests[i]
            if l:line_text =~ '^\s*' . l:req.method
                call vim_restman_utils#LogDebug("Found method: " . l:req.method . " at line " . l:current_line)
                call add(l:lines, [i, l:current_line, l:req.method])
            endif
        endfor
        let l:current_line += 1
    endwhile
    
    " Find the closest method line to the cursor
    let l:closest_distance = 999999
    for [req_index, line_num, method] in l:lines
        let l:distance = abs(l:cursor_line - line_num)
        call vim_restman_utils#LogDebug("Distance to " . method . " at line " . line_num . ": " . l:distance)
        if l:distance < l:closest_distance
            let l:closest_distance = l:distance
            let l:request_index = req_index
            call vim_restman_utils#LogDebug("New closest method: " . method . " (index " . req_index . ")")
        endif
    endfor
    
    " Check if we're close enough to consider this request valid
    if l:closest_distance > 10
        call vim_restman_utils#LogWarning("No method found close to cursor (closest distance: " . l:closest_distance . ")")
        let l:request_index = -1
    else
        call vim_restman_utils#LogDebug("Cursor is within " . l:closest_distance . " lines of the method")
    endif
    
    " Simple fallback: if there's only one request, use it
    if l:request_index == -1 && l:num_requests == 1
        call vim_restman_utils#LogDebug("Using fallback: Only one request available")
        let l:request_index = 0
    endif
    
    call vim_restman_utils#LogInfo("Detected request index: " . l:request_index)
    return l:request_index
endfunction

" --- Logging ---
" Log the initial state of windows and buffers
function! vim_restman_utils#LogInitialState()
    call vim_restman_utils#LogDebug("Current window layout: " . vim_restman_utils#GetWindowLayout())
    call vim_restman_utils#LogDebug("Current buffer list: " . vim_restman_utils#GetBufferList())
endfunction

" Log the final state of windows and buffers
function! vim_restman_utils#LogFinalState()
    call vim_restman_utils#LogDebug("Final window layout: " . vim_restman_utils#GetWindowLayout())
    call vim_restman_utils#LogDebug("Final buffer list: " . vim_restman_utils#GetBufferList())
endfunction

" --- Window and Buffer Info ---
" Get a string representation of the current window layout
" @return {string} Description of window layout
function! vim_restman_utils#GetWindowLayout()
    let l:layout = ""
    for i in range(1, winnr('$'))
        let l:bufname = bufname(winbufnr(i))
        let l:winid = win_getid(i)
        let l:layout .= "Win" . i . " (ID:" . l:winid . "):" . l:bufname . " | "
    endfor
    return l:layout
endfunction

" Get a string representation of the current buffer list
" @return {string} Description of buffer list
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
" Process JSON data using jq
" @param {string} json - The JSON string to process
" @param {string} filter - The jq filter to apply
" @return {string} The processed JSON result or original JSON if processing fails
function! vim_restman_utils#ProcessJsonWithJq(json, filter)
    call vim_restman_utils#LogDebug("Processing JSON with jq filter: " . a:filter)
    
    " Check if jq is installed
    if !executable('jq')
        call vim_restman_utils#LogWarning("jq is not installed. Please install jq for JSON processing capabilities.")
        return a:json
    endif
    
    " Log input for debugging
    call vim_restman_utils#LogDebug("JSON input preview (first 100 chars): " . 
                \ (strlen(a:json) > 100 ? strpart(a:json, 0, 100) . "..." : a:json))
    call vim_restman_utils#LogDebug("JSON input length: " . strlen(a:json))
    
    " Check for empty or invalid input
    if empty(a:json) || a:json =~ '^\s*$'
        call vim_restman_utils#LogWarning("Empty or whitespace-only JSON input")
        return a:json
    endif
    
    " Validate JSON using jq first and collect error output
    let [l:is_valid_json, l:error_msg] = s:IsValidJson(a:json)
    if !l:is_valid_json
        call vim_restman_utils#LogWarning("Invalid JSON input: " . l:error_msg)
        call vim_restman_utils#LogInfo("Will display raw response instead of attempting JSON formatting")
        return a:json
    endif
    
    " Create temporary files
    let l:tmpfile_in = tempname()
    let l:tmpfile_out = tempname()
    let l:tmpfile_err = tempname()
    
    " Write JSON to input file, making sure we handle multi-line content properly
    call writefile(split(a:json, "\n"), l:tmpfile_in)
    
    " Run jq command with a simple filter first to get pretty-printed JSON
    let l:cmd = 'jq ' . shellescape('.') . ' ' . shellescape(l:tmpfile_in) . 
                \ ' > ' . shellescape(l:tmpfile_out) . ' 2> ' . shellescape(l:tmpfile_err)
    call system(l:cmd)
    
    " Log the command result
    let l:exit_code = v:shell_error
    let l:error_output = join(readfile(l:tmpfile_err), "\n")
    call vim_restman_utils#LogDebug("Basic jq command exit code: " . l:exit_code)
    if !empty(l:error_output)
        call vim_restman_utils#LogDebug("jq error output: " . l:error_output)
    endif
    
    " If simple filter succeeded, try requested filter
    if l:exit_code == 0 && a:filter != '.'
        let l:cmd = 'jq ' . shellescape(a:filter) . ' ' . shellescape(l:tmpfile_in) . 
                    \ ' > ' . shellescape(l:tmpfile_out) . ' 2> ' . shellescape(l:tmpfile_err)
        call system(l:cmd)
        
        " Log the command result
        let l:exit_code = v:shell_error
        let l:error_output = join(readfile(l:tmpfile_err), "\n")
        call vim_restman_utils#LogDebug("Custom jq filter exit code: " . l:exit_code)
        if !empty(l:error_output)
            call vim_restman_utils#LogDebug("Custom jq filter error: " . l:error_output)
        endif
        
        " If filter failed, fall back to simple pretty-printing
        if l:exit_code != 0
            call vim_restman_utils#LogWarning("Custom jq filter failed, using basic pretty-printing")
            let l:cmd = 'jq ' . shellescape('.') . ' ' . shellescape(l:tmpfile_in) . 
                        \ ' > ' . shellescape(l:tmpfile_out) . ' 2> ' . shellescape(l:tmpfile_err)
            call system(l:cmd)
            
            " Log the fallback command result
            let l:exit_code = v:shell_error
            let l:error_output = join(readfile(l:tmpfile_err), "\n")
            call vim_restman_utils#LogDebug("Fallback jq command exit code: " . l:exit_code)
            if !empty(l:error_output)
                call vim_restman_utils#LogDebug("Fallback jq error: " . l:error_output)
            endif
        endif
    endif
    
    " Read processed JSON or return original if all processing failed
    if l:exit_code == 0
        let l:processed_json = join(readfile(l:tmpfile_out), "\n")
        call vim_restman_utils#LogDebug("JSON processing succeeded, returning formatted JSON")
        
        " Clean up temporary files
        call delete(l:tmpfile_in)
        call delete(l:tmpfile_out)
        call delete(l:tmpfile_err)
        
        return l:processed_json
    else
        call vim_restman_utils#LogWarning("JSON processing failed, returning raw response")
        
        " Clean up temporary files
        call delete(l:tmpfile_in)
        call delete(l:tmpfile_out)
        call delete(l:tmpfile_err)
        
        return a:json
    endif
endfunction

" Check if a string is valid JSON
" @param {string} json_string - The string to validate as JSON
" @return {list} [is_valid, error_message] - Boolean indicating if valid and error message if not
function! s:IsValidJson(json_string)
    if !executable('jq')
        return [0, "jq not installed"]
    endif
    
    " Create temporary files for validation
    let l:tmpfile_in = tempname()
    let l:tmpfile_err = tempname()
    
    " Write JSON string to file, making sure to preserve line breaks
    call writefile(split(a:json_string, "\n"), l:tmpfile_in)
    
    " Use jq to check if JSON is valid, capturing error output
    let l:cmd = 'jq . ' . shellescape(l:tmpfile_in) . ' >/dev/null 2> ' . shellescape(l:tmpfile_err)
    call system(l:cmd)
    let l:exit_code = v:shell_error
    let l:is_valid = (l:exit_code == 0)
    
    " Get error message if validation failed
    let l:error_msg = ""
    if !l:is_valid && filereadable(l:tmpfile_err)
        let l:error_msg = join(readfile(l:tmpfile_err), "\n")
    endif
    
    " Clean up temp files
    call delete(l:tmpfile_in)
    call delete(l:tmpfile_err)
    
    return [l:is_valid, l:error_msg]
endfunction

" --- String Manipulation ---
" Trim whitespace from beginning and end of a string
" @param {string} str - The string to trim
" @return {string} The trimmed string
function! vim_restman_utils#TrimString(str)
    return substitute(a:str, '^\s*\(.\{-}\)\s*$', '\1', '')
endfunction

" --- Logging and Error Handling ---
" Global debug mode flag
if !exists('g:vim_restman_debug')
    let g:vim_restman_debug = 0
endif

" Log debug message (only if debug mode is enabled)
" @param {string} message - The debug message to log
function! vim_restman_utils#LogDebug(message)
    if g:vim_restman_debug
        echom "[RestMan Debug] " . a:message
    endif
endfunction

" Log info message
" @param {string} message - The info message to log
function! vim_restman_utils#LogInfo(message)
    echom "[RestMan] " . a:message
endfunction

" Log warning message
" @param {string} message - The warning message to log
function! vim_restman_utils#LogWarning(message)
    echohl WarningMsg
    echom "[RestMan Warning] " . a:message
    echohl None
endfunction

" Log error message
" @param {string} message - The error message to log
function! vim_restman_utils#LogError(message)
    echohl ErrorMsg
    echom "[RestMan Error] " . a:message
    echohl None
endfunction

" --- Variable Substitution ---
" Substitute variables in text with their values
" @param {string} text - The text containing variable placeholders
" @param {dict} variables - Dictionary of variables to substitute
" @return {string} The text with variables substituted
function! vim_restman_utils#SubstituteVariables(text, variables)
    call vim_restman_utils#LogDebug("Substituting variables in text")
    let l:result = a:text
    
    " Handle different variable formats
    for [var_name, var_info] in items(a:variables)
        " Skip variables that aren't set
        if type(var_info) == v:t_dict && has_key(var_info, 'set') && !var_info.set
            continue
        endif
        
        " Get variable value based on variable structure
        let l:value = type(var_info) == v:t_dict && has_key(var_info, 'value') ? var_info.value : var_info
        
        " Replace different formats of variable references:
        " 1. :var_name format
        let l:result = substitute(l:result, ':' . var_name, l:value, 'g')
        
        " 2. {{var_name}} format (common in REST clients)
        let l:result = substitute(l:result, '{{' . var_name . '}}', l:value, 'g')
        
        " 3. $var_name format
        let l:result = substitute(l:result, '$' . var_name . '\>', l:value, 'g')
    endfor
    
    " Handle nested JSON objects via dot notation
    " This is a simple implementation - for complex cases, consider using a JSON parser
    let l:pattern = '{{([^.{}]\+)\.([^.{}]\+)}}'
    let l:match = matchstr(l:result, l:pattern)
    while !empty(l:match)
        let l:parts = split(l:match[2:-3], '\.')
        let l:obj_name = l:parts[0]
        let l:prop_name = l:parts[1]
        
        " Check if the object exists in variables
        if has_key(a:variables, l:obj_name)
            let l:obj_value = type(a:variables[l:obj_name]) == v:t_dict && has_key(a:variables[l:obj_name], 'value') 
                        \ ? a:variables[l:obj_name].value 
                        \ : a:variables[l:obj_name]
            
            " Try to parse as JSON
            try
                " For simplicity, we're using a naive approach here
                " In a real implementation, use a proper JSON parser
                let l:json_obj = l:obj_value
                let l:prop_pattern = '"' . l:prop_name . '"\s*:\s*\("[^"]*"\|[0-9]\+\)'
                let l:prop_match = matchstr(l:json_obj, l:prop_pattern)
                if !empty(l:prop_match)
                    let l:prop_value = matchstr(l:prop_match, ':\s*\zs\("[^"]*"\|[0-9]\+\)')
                    " Remove quotes from string values
                    let l:prop_value = substitute(l:prop_value, '^"\(.*\)"$', '\1', '')
                    let l:result = substitute(l:result, l:match, l:prop_value, 'g')
                endif
            catch
                " If JSON parsing fails, leave as is
                call vim_restman_utils#LogDebug("Failed to parse JSON for nested variable: " . l:match)
            endtry
        endif
        
        " Find next match
        let l:match = matchstr(l:result, l:pattern)
    endwhile
    
    return l:result
endfunction

" --- Curl Command Escaping ---
" Escape string for use in curl command
" @param {string} str - The string to escape
" @return {string} The escaped string
function! vim_restman_utils#EscapeCurlCommand(str)
    return escape(a:str, '"')
endfunction