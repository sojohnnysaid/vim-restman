" autoload/vim_restman_capture_manager.vim

" Global variable to store captured values
if !exists("g:vim_restman_captures")
    let g:vim_restman_captures = {}
endif

" Declare a capture variable for future use
" @param {string} var_name - The variable name to declare
function! vim_restman_capture_manager#DeclareCaptureVariable(var_name)
    let g:vim_restman_captures[a:var_name] = ''
    call vim_restman_utils#LogDebug("Declared capture variable: " . a:var_name)
endfunction

" Update a captured value with a new value
" @param {string} var_name - The variable name to update
" @param {string} value - The new value
function! vim_restman_capture_manager#UpdateCapturedValue(var_name, value)
    if has_key(g:vim_restman_captures, a:var_name)
        let g:vim_restman_captures[a:var_name] = a:value
        call vim_restman_utils#LogDebug("Updated capture variable: " . a:var_name . " = " . a:value)
    else
        call vim_restman_utils#LogWarning("Tried to update unknown capture variable: " . a:var_name)
    endif
endfunction

" Get a captured value
" @param {string} var_name - The variable name to get
" @return {string} The captured value or empty string if not found
function! vim_restman_capture_manager#GetCapturedValue(var_name)
    return get(g:vim_restman_captures, a:var_name, '')
endfunction

" Process a JSON response for capture variables
" @param {string} json_response - The JSON response to process
" @return {dict} Updated capture variables
function! vim_restman_capture_manager#ProcessJsonResponse(json_response)
    call vim_restman_utils#LogDebug("Processing JSON response for captures")
    let l:updated_captures = {}
    
    try
        " Try to parse as JSON using our improved JSON module
        if vim_restman_json#IsValidJson(a:json_response)
            " For each capture variable, try to extract value using jq
            for [key, _] in items(g:vim_restman_captures)
                if key =~ '^response\.'
                    let l:field = substitute(key, '^response\.', '', '')
                    let l:jq_filter = '.' . l:field
                    
                    let l:value = vim_restman_json#Extract(a:json_response, l:jq_filter)
                    let l:value = substitute(l:value, '^"\(.*\)"$', '\1', '')
                    
                    if !empty(l:value) && l:value != 'null'
                        call vim_restman_capture_manager#UpdateCapturedValue(key, l:value)
                        let l:updated_captures[key] = l:value
                    endif
                endif
            endfor
        else
            " Fall back to basic regex pattern matching for non-JSON responses
            call vim_restman_utils#LogDebug("Not valid JSON, using regex pattern matching for captures")
            for [key, _] in items(g:vim_restman_captures)
                if key =~ '^response\.'
                    let l:field = substitute(key, '^response\.', '', '')
                    let l:pattern = '"' . l:field . '"\s*:\s*\("[^"]*"\|[0-9]\+\)'
                    let l:match = matchstr(a:json_response, l:pattern)
                    
                    if !empty(l:match)
                        let l:value = matchstr(l:match, ':\s*\zs\("[^"]*"\|[0-9]\+\)')
                        let l:value = substitute(l:value, '^"\(.*\)"$', '\1', '')
                        call vim_restman_capture_manager#UpdateCapturedValue(key, l:value)
                        let l:updated_captures[key] = l:value
                    endif
                endif
            endfor
        endif
    catch
        call vim_restman_utils#LogError("Error processing JSON response: " . v:exception)
    endtry
    
    call vim_restman_utils#LogDebug("Updated " . len(l:updated_captures) . " capture variables")
    return l:updated_captures
endfunction

" Substitute captured values in text
" @param {string} text - The text to process
" @return {string} Text with captured values substituted
function! vim_restman_capture_manager#SubstituteCapturedValues(text)
    let l:result = a:text
    
    for [key, value] in items(g:vim_restman_captures)
        " Support multiple variable formats
        let l:result = substitute(l:result, ':' . key, value, 'g')
        let l:result = substitute(l:result, '{{' . key . '}}', value, 'g')
    endfor
    
    return l:result
endfunction

" Get all captured values
" @return {dict} All captured values
function! vim_restman_capture_manager#GetAllCapturedValues()
    return g:vim_restman_captures
endfunction

" Clear all captured values
function! vim_restman_capture_manager#ClearAllCapturedValues()
    let g:vim_restman_captures = {}
    call vim_restman_utils#LogDebug("Cleared all captured values")
endfunction