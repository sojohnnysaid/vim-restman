" autoload/vim_restman_buffer_manager.vim

" Global variable to store the RestMan buffer number
let s:restman_bufnr = -1

function! vim_restman_buffer_manager#PopulateRestManBuffer(parsed_data, curl_command, output, request_index)
    echom "vim_restman_buffer_manager#PopulateRestManBuffer() called"
    
    " Generate content
    let l:content = s:GenerateBufferContent(a:parsed_data, a:curl_command, a:output, a:request_index)
    
    " Clear and populate the buffer
    setlocal modifiable
    %delete _
    call setline(1, split(l:content, "\n"))
    setlocal nomodifiable

    " Set up syntax highlighting
    call s:SetupSyntaxHighlighting()
endfunction

function! s:GenerateBufferContent(parsed_data, curl_command, output, request_index)
    let l:content = "=== Globals ===\n\n"
    for [key, value] in items(a:parsed_data.globals)
        let l:content .= key . ": " . value . "\n"
    endfor
    
    let l:content .= "\n=== Requests ===\n"
    if len(a:parsed_data.requests) > a:request_index
        let l:request = a:parsed_data.requests[a:request_index]
        let l:content .= "Method: " . get(l:request, 'method', '') . "\n"
        let l:content .= "Endpoint: " . get(l:request, 'endpoint', '') . "\n"
        if has_key(l:request, 'body')
            let l:content .= "Body:\n" . l:request.body . "\n"
        endif
    else
        let l:content .= "No request found at index " . a:request_index . "\n"
    endif
    
    let l:content .= "\n=== Curl Command ===\n" . a:curl_command . "\n"
    let l:content .= "\n=== Curl Output ===\n" . s:PrettyPrintJson(a:output)

    return l:content
endfunction



function! s:SetupSyntaxHighlighting()
    if has('syntax') && exists('g:syntax_on')
        " Clear any existing syntax
        syntax clear

        " Define the Curl Output region
        syntax region RestManCurlOutput start=/^=== Curl Output ===$/hs=e+1 end=/\%$/

        " Define JSON syntax within the Curl Output region
        syntax region RestManJson start=/{/ end=/}/ contained containedin=RestManCurlOutput contains=RestManJson,RestManJsonKeyValue fold
        syntax match RestManJsonKeyValue /"\zs[^"]\+\ze"\s*:/ contained containedin=RestManJson

        " Set highlighting colors
        highlight RestManJsonKeyValue ctermfg=114 guifg=#87d787

        " Disable highlighting for other elements
        highlight RestManJson ctermfg=NONE guifg=NONE
    endif
endfunction




function! s:PrettyPrintJson(json)
    if executable('jq')
        let l:cmd = 'jq .'
        let l:pretty_json = system(l:cmd, a:json)
        return l:pretty_json
    else
        " Fallback to basic indentation if jq is not available
        let l:lines = split(a:json, '.\zs')
        let l:indent = 0
        let l:pretty = []
        for l:char in l:lines
            if l:char ==# '{'
                call add(l:pretty, repeat(' ', l:indent) . l:char)
                let l:indent += 2
            elseif l:char ==# '}'
                let l:indent -= 2
                call add(l:pretty, repeat(' ', l:indent) . l:char)
            elseif l:char ==# ','
                call add(l:pretty, l:char)
                call add(l:pretty, '')
            else
                call add(l:pretty, repeat(' ', l:indent) . l:char)
            endif
        endfor
        return join(l:pretty, "\n")
    endif
endfunction




function! vim_restman_buffer_manager#GetRestManBufferNumber()
    return s:restman_bufnr
endfunction

function! vim_restman_buffer_manager#ClearRestManBuffer()
    if s:restman_bufnr != -1 && bufexists(s:restman_bufnr)
        execute 'bwipeout! ' . s:restman_bufnr
        let s:restman_bufnr = -1
    endif
endfunction

