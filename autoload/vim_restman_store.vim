" autoload/vim_restman_store.vim
" Variable store for vim-restman

" Global variable to store all variables
if !exists('g:vim_restman_variables')
    let g:vim_restman_variables = {}
endif

" Global variable to store request history
if !exists('g:vim_restman_history')
    let g:vim_restman_history = []
endif

" Initialize the variable store
" @return {dict} The initialized variable store
function! vim_restman_store#Initialize()
    let g:vim_restman_variables = {}
    call vim_restman_utils#LogDebug("Variable store initialized")
    return g:vim_restman_variables
endfunction

" Add a variable to the store
" @param {string} name - The variable name
" @param {string} value - The variable value
" @param {boolean} is_set - Whether the variable is set or just declared
function! vim_restman_store#SetVariable(name, value, is_set)
    let g:vim_restman_variables[a:name] = {'value': a:value, 'set': a:is_set}
    call vim_restman_utils#LogDebug("Variable set: " . a:name . " = " . a:value . " (set: " . a:is_set . ")")
endfunction

" Get a variable from the store
" @param {string} name - The variable name
" @return {dict|string} The variable info or empty string if not found
function! vim_restman_store#GetVariable(name)
    if has_key(g:vim_restman_variables, a:name)
        return g:vim_restman_variables[a:name]
    endif
    return ''
endfunction

" Get all variables from the store
" @return {dict} All variables
function! vim_restman_store#GetAllVariables()
    return g:vim_restman_variables
endfunction

" Process capture variables from response
" @param {string} response - The response to process
" @return {dict} Captured variables
function! vim_restman_store#ProcessCaptures(response)
    let l:captures = {}
    
    " Process only for JSON responses
    if vim_restman_json#IsValidJson(a:response)
        " Find all capture variables
        for [var_name, var_info] in items(g:vim_restman_variables)
            " Only process variables that match the capture pattern
            if var_name =~ '^response\.'
                let l:field = substitute(var_name, '^response\.', '', '')
                let l:jq_filter = '.' . l:field
                
                let l:value = vim_restman_json#Extract(a:response, l:jq_filter)
                let l:value = substitute(l:value, '^"\(.*\)"$', '\1', '')
                
                if !empty(l:value) && l:value != 'null'
                    call vim_restman_store#SetVariable(var_name, l:value, 1)
                    let l:captures[var_name] = l:value
                endif
            endif
        endfor
    else
        " Try regex extraction for non-JSON responses
        call vim_restman_utils#LogDebug("Non-JSON response, using regex patterns")
        for [var_name, var_info] in items(g:vim_restman_variables)
            if var_name =~ '^response\.'
                let l:field = substitute(var_name, '^response\.', '', '')
                let l:pattern = '"' . l:field . '"\s*:\s*\("[^"]*"\|[0-9]\+\)'
                let l:match = matchstr(a:response, l:pattern)
                
                if !empty(l:match)
                    let l:value = matchstr(l:match, ':\s*\zs\("[^"]*"\|[0-9]\+\)')
                    let l:value = substitute(l:value, '^"\(.*\)"$', '\1', '')
                    call vim_restman_store#SetVariable(var_name, l:value, 1)
                    let l:captures[var_name] = l:value
                endif
            endif
        endfor
    endif
    
    return l:captures
endfunction

" Substitute variables in text
" @param {string} text - The text containing variable references
" @return {string} The text with variables substituted
function! vim_restman_store#SubstituteVariables(text)
    let l:result = a:text
    
    for [var_name, var_info] in items(g:vim_restman_variables)
        if var_info.set
            " Replace different formats of variable references
            let l:result = substitute(l:result, ':' . var_name, var_info.value, 'g')
            let l:result = substitute(l:result, '{{' . var_name . '}}', var_info.value, 'g')
            let l:result = substitute(l:result, '$' . var_name . '\>', var_info.value, 'g')
        endif
    endfor
    
    return l:result
endfunction

" Add a request to the history
" @param {dict} request - The request details
" @param {string} response - The response
" @param {string} buffer_name - The buffer name for the response
function! vim_restman_store#AddToHistory(request, response, buffer_name)
    let l:entry = {
        \ 'timestamp': localtime(),
        \ 'request': a:request,
        \ 'response': a:response,
        \ 'buffer_name': a:buffer_name
    \ }
    
    call add(g:vim_restman_history, l:entry)
    call vim_restman_utils#LogDebug("Added request to history: " . a:request.method . " " . a:request.endpoint)
endfunction

" Get the request history
" @return {list} The request history
function! vim_restman_store#GetHistory()
    return g:vim_restman_history
endfunction