" autoload/vim_restman_buffer.vim
" Buffer management for vim-restman

" Global variables to store buffer information
if !exists('g:vim_restman_result_buffers')
    let g:vim_restman_result_buffers = []
endif

" Create a new result buffer for a request
" @param {dict} request - The request details
" @param {string} method - The HTTP method
" @param {string} endpoint - The endpoint URL
" @return {dict} Buffer information including buffer number and name
function! vim_restman_buffer#CreateResultBuffer(request, method, endpoint)
    " Generate a unique buffer name
    let l:timestamp = strftime('%H%M%S')
    let l:endpoint_short = substitute(a:endpoint, '[^a-zA-Z0-9]', '', 'g')
    if strlen(l:endpoint_short) > 20
        let l:endpoint_short = strpart(l:endpoint_short, 0, 20)
    endif
    let l:buffer_name = 'RestMan-' . l:timestamp . '-' . a:method . '-' . l:endpoint_short
    
    " Check if there's already a result split window open
    let l:existing_windows = 0
    for buf_info in g:vim_restman_result_buffers
        let l:win_ids = win_findbuf(buf_info.number)
        if !empty(l:win_ids)
            let l:existing_windows = 1
            call win_gotoid(l:win_ids[0])
            break
        endif
    endfor
    
    " Only create a new split if no result window exists
    if !l:existing_windows
        execute 'vsplit'
    endif
    
    " Create the buffer
    execute 'edit ' . l:buffer_name
    
    " Configure the buffer
    setlocal buftype=nofile
    setlocal bufhidden=hide
    setlocal noswapfile
    setlocal modifiable
    
    " Clear the buffer content
    silent! execute '1,$delete _'
    
    " Store buffer info
    let l:buffer_info = {
        \ 'name': l:buffer_name,
        \ 'number': bufnr('%'),
        \ 'window': win_getid(),
        \ 'request': a:request,
        \ 'method': a:method,
        \ 'endpoint': a:endpoint,
        \ 'timestamp': localtime()
    \ }
    
    call add(g:vim_restman_result_buffers, l:buffer_info)
    call vim_restman_utils#LogInfo("Created result buffer: " . l:buffer_name)
    
    return l:buffer_info
endfunction

" Populate a result buffer with request and response details
" @param {dict} buffer_info - The buffer information
" @param {dict} request - The complete request details
" @param {string} curl_command - The curl command used
" @param {string} response - The response content
" @param {dict} captures - Any captured variables
" @param {dict} headers - Response headers (if available)
function! vim_restman_buffer#PopulateResultBuffer(buffer_info, request, curl_command, response, captures, headers)
    " Make sure we're in the right buffer
    if bufnr('%') != a:buffer_info.number
        execute 'buffer ' . a:buffer_info.number
    endif
    
    " Set the buffer as modifiable
    setlocal modifiable
    
    " Generate content
    let l:content = []
    
    " Add header section
    call add(l:content, '# Request: ' . a:request.method . ' ' . a:request.endpoint)
    call add(l:content, '# Executed at: ' . strftime('%c'))
    call add(l:content, '')
    
    " Add request details section
    call add(l:content, '## Request Details')
    call add(l:content, '')
    call add(l:content, '### HTTP Method')
    call add(l:content, a:request.method)
    call add(l:content, '')
    call add(l:content, '### URL')
    call add(l:content, a:request.endpoint)
    call add(l:content, '')
    
    " Add headers if available
    if has_key(a:request, 'headers') && !empty(a:request.headers)
        call add(l:content, '### Headers')
        for header_line in split(a:request.headers, "\n")
            call add(l:content, header_line)
        endfor
        call add(l:content, '')
    endif
    
    " Add body if available
    if has_key(a:request, 'body') && !empty(a:request.body)
        call add(l:content, '### Body')
        for body_line in split(a:request.body, "\n")
            call add(l:content, body_line)
        endfor
        call add(l:content, '')
    endif
    
    " Add curl command
    call add(l:content, '### Generated Curl Command')
    let l:formatted_curl = vim_restman_curl_builder#FormatCurlCommand(a:curl_command)
    for curl_line in split(l:formatted_curl, "\n")
        call add(l:content, curl_line)
    endfor
    call add(l:content, '')
    
    " Add response section
    call add(l:content, '## Response')
    call add(l:content, '')
    
    " Add response headers if available
    if !empty(a:headers)
        call add(l:content, '### Response Headers')
        for header_line in split(a:headers, "\n")
            call add(l:content, header_line)
        endfor
        call add(l:content, '')
    endif
    
    " Add response body
    call add(l:content, '### Response Body')
    for response_line in split(a:response, "\n")
        call add(l:content, response_line)
    endfor
    call add(l:content, '')
    
    " Add captured variables if any
    if !empty(a:captures)
        call add(l:content, '## Captured Variables')
        call add(l:content, '')
        for [var_name, var_value] in items(a:captures)
            call add(l:content, var_name . ': ' . var_value)
        endfor
        call add(l:content, '')
    endif
    
    " Set the buffer content
    call setline(1, l:content)
    
    " Move cursor to the top
    normal! gg
    
    " Set the buffer as non-modifiable
    setlocal nomodifiable
    
    " Apply syntax highlighting
    call s:SetupSyntaxHighlighting()
    
    call vim_restman_utils#LogInfo("Populated result buffer with " . len(l:content) . " lines")
endfunction

" Add execution metadata to the result buffer
" @param {dict} buffer_info - The buffer information
" @param {string} status_code - HTTP status code
" @param {float} execution_time - Request execution time in milliseconds
" @param {number} exit_status - Curl exit status
function! vim_restman_buffer#AddExecutionMetadata(buffer_info, status_code, execution_time, exit_status)
    " Make sure we're in the right buffer
    if bufnr('%') != a:buffer_info.number
        execute 'buffer ' . a:buffer_info.number
    endif
    
    " Find position to insert metadata (after Response section header)
    let l:line_num = search('^## Response$', 'n')
    if l:line_num > 0
        " Set the buffer as modifiable
        setlocal modifiable
        
        " Generate metadata content
        let l:metadata = []
        call add(l:metadata, '')
        call add(l:metadata, '### Execution Metadata')
        
        " Add status code if available
        if !empty(a:status_code)
            call add(l:metadata, 'Status Code: ' . a:status_code)
        endif
        
        " Add execution time
        call add(l:metadata, 'Execution Time: ' . printf('%.2f', a:execution_time) . ' ms')
        
        " Add curl exit status
        call add(l:metadata, 'Curl Exit Status: ' . a:exit_status)
        
        " Calculate content type from headers if possible
        let l:content_type = s:ExtractContentType()
        if !empty(l:content_type)
            call add(l:metadata, 'Content Type: ' . l:content_type)
        endif
        
        call add(l:metadata, '')
        
        " Insert metadata after Response section header
        call append(l:line_num, l:metadata)
        
        " Set buffer back to non-modifiable
        setlocal nomodifiable
        
        " Update syntax highlighting
        call s:SetupSyntaxHighlighting()
        
        call vim_restman_utils#LogInfo("Added execution metadata to buffer")
    endif
endfunction

" Extract Content-Type from headers section in buffer
" @return {string} Content type or empty string if not found
function! s:ExtractContentType()
    let l:content_type = ''
    let l:header_section_start = search('^### Response Headers$', 'n')
    let l:header_section_end = search('^$', 'n', l:header_section_start)
    
    if l:header_section_start > 0 && l:header_section_end > 0
        " Search for Content-Type header
        for l:line_num in range(l:header_section_start + 1, l:header_section_end - 1)
            let l:line = getline(l:line_num)
            let l:matches = matchlist(l:line, 'Content-Type:\s*\(.\+\)')
            if len(l:matches) > 1
                let l:content_type = l:matches[1]
                break
            endif
        endfor
    endif
    
    return l:content_type
endfunction

" Navigate to a specific result buffer
" @param {number} index - The index of the buffer in the list
" @return {boolean} True if navigation was successful
function! vim_restman_buffer#NavigateToBuffer(index)
    if a:index >= 0 && a:index < len(g:vim_restman_result_buffers)
        let l:buffer_info = g:vim_restman_result_buffers[a:index]
        
        " Check if the buffer still exists
        if bufexists(l:buffer_info.number)
            " Check if buffer is displayed in a window
            let l:win_ids = win_findbuf(l:buffer_info.number)
            
            if !empty(l:win_ids)
                " Buffer is displayed, go to window
                call win_gotoid(l:win_ids[0])
            else
                " Buffer exists but not displayed, split and show it
                execute 'vsplit'
                execute 'buffer ' . l:buffer_info.number
            endif
            
            call vim_restman_utils#LogInfo("Navigated to buffer: " . l:buffer_info.name)
            return 1
        else
            call vim_restman_utils#LogWarning("Buffer no longer exists: " . l:buffer_info.name)
            " Remove from list
            call remove(g:vim_restman_result_buffers, a:index)
            return 0
        endif
    else
        call vim_restman_utils#LogWarning("Invalid buffer index: " . a:index)
        return 0
    endif
endfunction

" List all result buffers
" @return {list} List of buffer information
function! vim_restman_buffer#ListResultBuffers()
    " First clean up any stale entries
    call s:CleanUpStaleBuffers()
    
    " Return the cleaned list
    return g:vim_restman_result_buffers
endfunction

" Clean up any stale buffer entries
function! s:CleanUpStaleBuffers()
    let l:valid_buffers = []
    
    for buffer_info in g:vim_restman_result_buffers
        if bufexists(buffer_info.number)
            call add(l:valid_buffers, buffer_info)
        endif
    endfor
    
    let g:vim_restman_result_buffers = l:valid_buffers
endfunction

" Close all result buffers
function! vim_restman_buffer#CloseAllResultBuffers()
    for buffer_info in g:vim_restman_result_buffers
        if bufexists(buffer_info.number)
            execute 'bwipeout! ' . buffer_info.number
        endif
    endfor
    
    let g:vim_restman_result_buffers = []
    call vim_restman_utils#LogInfo("Closed all result buffers")
endfunction

" Set up syntax highlighting for a result buffer
function! s:SetupSyntaxHighlighting()
    if has('syntax') && exists('g:syntax_on')
        " Set the filetype to markdown for basic formatting
        setlocal ft=markdown
        
        " Add custom syntax for request and response sections
        syntax region RestManRequestMethod start=/^### HTTP Method$/ end=/^$/ contains=RestManHeader
        syntax region RestManRequestURL start=/^### URL$/ end=/^$/ contains=RestManHeader
        syntax region RestManRequestHeaders start=/^### Headers$/ end=/^$/ contains=RestManHeader,RestManHeaderLine
        syntax region RestManRequestBody start=/^### Body$/ end=/^$/ contains=RestManHeader
        syntax region RestManResponseBody start=/^### Response Body$/ end=/^$/ contains=RestManHeader
        syntax region RestManCurl start=/^### Generated Curl Command$/ end=/^$/ contains=RestManHeader,RestManCurlOption
        syntax region RestManMetadata start=/^### Execution Metadata$/ end=/^$/ contains=RestManHeader,RestManStatusSuccess,RestManStatusError,RestManMetadataLine
        
        " Define syntax matches
        syntax match RestManHeader /^###.*$/
        syntax match RestManHeaderLine /^[A-Za-z-]\+:.*$/ contained
        syntax match RestManCurlOption /\s\zs-\w\+/ contained
        syntax match RestManMetadataLine /^[A-Za-z ]\+:.*$/ contained
        syntax match RestManStatusSuccess /Status Code: 2[0-9][0-9]/ contained
        syntax match RestManStatusError /Status Code: [45][0-9][0-9]/ contained
        
        " Highlight JSON in response bodies
        syntax region RestManJson start=/{/ end=/}/ contained contains=RestManJson,RestManJsonKeyValue fold
        syntax match RestManJsonKeyValue /"\zs[^"]\+\ze"\s*:/ contained
        
        " Set highlighting colors
        highlight RestManHeader ctermfg=45 guifg=#00d7ff
        highlight RestManHeaderLine ctermfg=118 guifg=#87ff00
        highlight RestManCurlOption ctermfg=208 guifg=#ff8700
        highlight RestManJsonKeyValue ctermfg=81 guifg=#5fd7ff
        highlight RestManMetadataLine ctermfg=251 guifg=#c6c6c6
        highlight RestManStatusSuccess ctermfg=120 guifg=#87ff87
        highlight RestManStatusError ctermfg=203 guifg=#ff5f5f
        
        call vim_restman_utils#LogDebug("Applied syntax highlighting to result buffer")
    endif
endfunction