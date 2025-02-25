" autoload/vim_restman_json.vim
" JSON processing utilities for vim-restman

" Process JSON data using jq with enhanced error handling
" @param {string} json - The JSON string to process
" @param {string} filter - The jq filter to apply
" @return {string} The processed JSON result or original JSON if processing fails
function! vim_restman_json#ProcessWithJq(json, filter)
    call vim_restman_utils#LogInfo("Processing JSON response...")
    call vim_restman_utils#LogDebug("Using jq filter: " . a:filter)
    
    " Check if jq is installed
    if !executable('jq')
        call vim_restman_utils#LogWarning("jq is not installed. Please install jq for JSON processing capabilities.")
        return a:json
    endif
    
    " Log input for debugging
    if g:vim_restman_debug
        call vim_restman_utils#LogDebug("JSON input preview (first 100 chars): " . 
                    \ (strlen(a:json) > 100 ? strpart(a:json, 0, 100) . "..." : a:json))
        call vim_restman_utils#LogDebug("JSON input length: " . strlen(a:json))
    endif
    
    " Check for empty or invalid input
    if empty(a:json) || a:json =~ '^\s*$'
        call vim_restman_utils#LogWarning("Empty or whitespace-only JSON input")
        return a:json
    endif
    
    " Validate JSON using jq first and collect error output
    let [l:is_valid_json, l:error_msg] = s:ValidateJson(a:json)
    if !l:is_valid_json
        call vim_restman_utils#LogWarning("Invalid JSON input: " . l:error_msg)
        call vim_restman_utils#LogInfo("Will display raw response instead of attempting JSON formatting")
        return a:json
    endif
    
    " Create temporary files
    let l:tmpfile_in = tempname()
    let l:tmpfile_out = tempname()
    let l:tmpfile_err = tempname()
    
    " Write JSON to input file, making sure we handle multi-line content correctly
    call writefile(split(a:json, "\n"), l:tmpfile_in)
    
    " Run jq command with a simple filter first to get pretty-printed JSON
    let l:cmd = 'jq ' . shellescape('.') . ' ' . shellescape(l:tmpfile_in) . 
                \ ' > ' . shellescape(l:tmpfile_out) . ' 2> ' . shellescape(l:tmpfile_err)
    call system(l:cmd)
    
    " Log the command result
    let l:exit_code = v:shell_error
    let l:error_output = filereadable(l:tmpfile_err) ? join(readfile(l:tmpfile_err), "\n") : ""
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
        let l:error_output = filereadable(l:tmpfile_err) ? join(readfile(l:tmpfile_err), "\n") : ""
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
            let l:error_output = filereadable(l:tmpfile_err) ? join(readfile(l:tmpfile_err), "\n") : ""
            call vim_restman_utils#LogDebug("Fallback jq command exit code: " . l:exit_code)
            if !empty(l:error_output)
                call vim_restman_utils#LogDebug("Fallback jq error: " . l:error_output)
            endif
        endif
    endif
    
    " Read processed JSON or return original if all processing failed
    if l:exit_code == 0 && filereadable(l:tmpfile_out)
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

" Format JSON string for display
" @param {string} json - The JSON string to format
" @return {string} The formatted JSON string or original if not JSON
function! vim_restman_json#Format(json)
    return vim_restman_json#ProcessWithJq(a:json, '.')
endfunction

" Extract a value from JSON using a jq path expression
" @param {string} json - The JSON string to extract from
" @param {string} path - The jq path expression (e.g., '.items[0].id')
" @return {string} The extracted value or empty string if not found
function! vim_restman_json#Extract(json, path)
    return vim_restman_json#ProcessWithJq(a:json, a:path)
endfunction

" Validate if a string is valid JSON
" @param {string} json_string - The string to validate
" @return {list} [is_valid, error_message] - Boolean indicating if valid and error message if not
function! s:ValidateJson(json_string)
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

" Check if a string is valid JSON (public interface)
" @param {string} json_string - The string to validate
" @return {boolean} True if valid JSON, False otherwise
function! vim_restman_json#IsValidJson(json_string)
    let [l:is_valid, l:error_msg] = s:ValidateJson(a:json_string)
    return l:is_valid
endfunction