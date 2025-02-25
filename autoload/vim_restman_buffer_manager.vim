" autoload/vim_restman_buffer_manager.vim

" Global variable to store the RestMan buffer number
let s:restman_bufnr = -1

" Populate the RestMan buffer with content
" @param {dict} parsed_data - The parsed data structure
" @param {string} curl_command - The curl command that was executed
" @param {string} output - The output from the curl command
" @param {number} request_index - The index of the request
" @param {dict} updated_captures - The captured variables from the response
" @param {dict} variables - All variables
" @param {string} headers - The response headers
function! vim_restman_buffer_manager#PopulateRestManBuffer(parsed_data, curl_command, output, request_index, updated_captures, variables, headers)
    call vim_restman_utils#LogInfo("Updating RestMan buffer with request " . (a:request_index + 1) . " results")
    
    " Make sure we're working with the right buffer
    let l:current_bufnr = bufnr('%')
    if l:current_bufnr != s:restman_bufnr && s:restman_bufnr != -1
        call vim_restman_utils#LogWarning("Buffer mismatch - current: " . l:current_bufnr . ", expected: " . s:restman_bufnr)
        " Try to switch to the correct buffer
        execute 'buffer ' . s:restman_bufnr
    endif
    
    " Generate content in new Markdown format
    let l:content = s:GenerateMarkdownContent(a:parsed_data, a:curl_command, a:output, a:request_index, a:updated_captures, a:variables, a:headers)
    
    " Clear and populate the buffer
    setlocal modifiable
    silent! execute '1,$delete _'  " Delete all content from the buffer
    call setline(1, split(l:content, "\n"))
    normal! gg           " Move cursor to top
    setlocal nomodifiable
    
    " Set up syntax highlighting
    setlocal ft=markdown
    
    " Get the number of lines in the buffer
    let l:line_count = line('$')
    call vim_restman_utils#LogDebug("RestMan buffer populated with " . l:line_count . " lines")
    redraw!  " Force redraw to ensure content is displayed
    
    " Make sure we store the current buffer number for reuse
    let s:restman_bufnr = bufnr('%')$')
    call vim_restman_utils#LogDebug("RestMan buffer populated with " . l:line_count . " lines")
    redraw!  " Force redraw to ensure content is displayed
    
    " Make sure we store the current buffer number for reuse
    let s:restman_bufnr = bufnr('%')
endfunction

" Generate Markdown content for the RestMan buffer
" @param {dict} parsed_data - The parsed data structure
" @param {string} curl_command - The curl command that was executed
" @param {string} output - The output from the curl command
" @param {number} request_index - The index of the request
" @param {dict} updated_captures - The captured variables from the response
" @param {dict} variables - All variables
" @param {string} headers - The response headers
" @return {string} The generated buffer content
function! s:GenerateMarkdownContent(parsed_data, curl_command, output, request_index, updated_captures, variables, headers)
    let l:content = ""
    
    " Add request info
    if len(a:parsed_data.requests) > a:request_index
        let l:request = a:parsed_data.requests[a:request_index]
        let l:content .= "# Request: " . get(l:request, 'method', '') . " " . get(l:request, 'endpoint', '') . "\n"
        let l:content .= "# Executed at: " . strftime("%c") . "\n\n"
        
        " Add request details
        let l:content .= "## Request Details\n\n"
        let l:content .= "### HTTP Method\n" . get(l:request, 'method', '') . "\n\n"
        let l:content .= "### URL\n" . get(l:request, 'endpoint', '') . "\n\n"
        
        " Add headers
        if has_key(l:request, 'headers')
            let l:content .= "### Headers\n" . l:request.headers . "\n\n"
        endif
        
        " Add body
        if has_key(l:request, 'body')
            let l:content .= "### Body\n" . l:request.body . "\n\n"
        endif
        
        " Add curl command
        let l:content .= "### Generated Curl Command\n" . vim_restman_curl_builder#FormatCurlCommand(a:curl_command) . "\n\n"
        
        " Add response section
        let l:content .= "## Response\n\n"
        
        " Add response headers
        if !empty(a:headers)
            let l:content .= "### Response Headers\n" . a:headers . "\n\n"
        endif
        
        " Add response body
        let l:content .= "### Response Body\n" . a:output . "\n\n"
        
        " Add captured variables
        if !empty(a:updated_captures)
            let l:content .= "## Captured Variables\n\n"
            for [key, value] in items(a:updated_captures)
                let l:content .= key . ": " . value . "\n"
            endfor
        endif
    else
        let l:content .= "# Error: No request found at index " . a:request_index . "\n"
    endif
    
    return l:content
endfunction

" Set up syntax highlighting for the RestMan buffer
function! s:SetupSyntaxHighlighting()
    if has('syntax') && exists('g:syntax_on')
        " Clear any existing syntax
        syntax clear
        
        " Define syntax regions
        syntax region RestManGlobals start=/^=== Globals ===$/hs=e+1 end=/^===.*===$/ contains=RestManKeyValue
        syntax region RestManVariables start=/^=== Variables ===$/hs=e+1 end=/^===.*===$/ contains=RestManKeyValue,RestManNotSet
        syntax region RestManRequests start=/^=== Requests ===$/hs=e+1 end=/^===.*===$/ contains=RestManKeyValue
        syntax region RestManCurlCommand start=/^=== Curl Command ===$/hs=e+1 end=/^===.*===$/ contains=RestManCurlOption
        syntax region RestManCurlOutput start=/^=== Response ===$/hs=e+1 end=/^===.*===$/ contains=RestManJson,RestManJsonKeyValue
        syntax region RestManCapturedVariables start=/^=== Captured Variables ===$/hs=e+1 end=/\%$/ contains=RestManKeyValue
        
        " Define syntax matches
        syntax match RestManKeyValue /^\s*\zs\w\+\ze:/ contained
        syntax match RestManNotSet /(not set)/ contained
        syntax match RestManCurlOption /\s\zs-\w\+/ contained
        syntax region RestManJson start=/{/ end=/}/ contained contains=RestManJson,RestManJsonKeyValue fold
        syntax match RestManJsonKeyValue /"\zs[^"]\+\ze"\s*:/ contained
        
        " Set highlighting colors
        highlight RestManKeyValue ctermfg=114 guifg=#87d787
        highlight RestManNotSet ctermfg=203 guifg=#ff5f5f
        highlight RestManCurlOption ctermfg=208 guifg=#ff8700
        highlight RestManJsonKeyValue ctermfg=81 guifg=#5fd7ff
        highlight RestManJson ctermfg=NONE guifg=NONE
        
        call vim_restman_utils#LogDebug("Syntax highlighting set up")
    endif
endfunction

" Get the RestMan buffer number
" @return {number} The buffer number
function! vim_restman_buffer_manager#GetRestManBufferNumber()
    return s:restman_bufnr
endfunction

" Clear the RestMan buffer
function! vim_restman_buffer_manager#ClearRestManBuffer()
    if s:restman_bufnr != -1 && bufexists(s:restman_bufnr)
        execute 'bwipeout! ' . s:restman_bufnr
        let s:restman_bufnr = -1
        call vim_restman_utils#LogDebug("RestMan buffer cleared")
    endif
endfunction

" Set the RestMan buffer number
" @param {number} bufnr - The buffer number to set
function! vim_restman_buffer_manager#SetRestManBufferNumber(bufnr)
    let s:restman_bufnr = a:bufnr
    call vim_restman_utils#LogDebug("RestMan buffer number set to " . a:bufnr)
endfunction