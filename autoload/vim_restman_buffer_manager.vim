" autoload/vim_restman_buffer_manager.vim

" Global variable to store the RestMan buffer number
let s:restman_bufnr = -1


function! vim_restman_buffer_manager#PopulateRestManBuffer(parsed_data, curl_command, output, updated_captures, variables)
    " echom "vim_restman_buffer_manager#PopulateRestManBuffer() called"
    
    " Generate content
    let l:content = s:GenerateBufferContent(a:parsed_data, a:curl_command, a:output, a:updated_captures, a:variables)
    
    " Clear and populate the buffer
    setlocal modifiable
    %delete _
    call setline(1, split(l:content, "\n"))
    setlocal nomodifiable

    " Set filetype to trigger any potential filetype-specific settings
    setlocal filetype=restman

    " Set up syntax highlighting
    call s:SetupSyntaxHighlighting()

    " Force a redraw to ensure syntax highlighting is applied
    redraw!
endfunction


function! s:GenerateBufferContent(parsed_data, curl_command, output, updated_captures, variables)
    let l:content = ""

    " Commented out Globals section
    " let l:content = "=== Globals ===\n\n"
    " for [key, value] in items(a:parsed_data.globals)
    "     let l:content .= key . ": " . string(value) . "\n"
    " endfor
    
    " Commented out Variables section
    " let l:content .= "\n=== Variables ===\n"
    " for [var_name, var_info] in items(a:variables)
    "     let l:content .= var_name . "\n"
    " endfor
    
    " Commented out Current Request section
    " let l:content .= "\n=== Current Request ===\n"
    " if !empty(a:parsed_data.requests)
    "     let l:request = a:parsed_data.requests[0]
    "     let l:content .= "Method: " . get(l:request, 'method', '') . "\n"
    "     let l:content .= "Endpoint: " . get(l:request, 'endpoint', '') . "\n"
    "     if has_key(l:request, 'headers')
    "         let l:content .= "Headers:\n" . l:request.headers . "\n"
    "     endif
    "     if has_key(l:request, 'body')
    "         let l:content .= "Body:\n" . l:request.body . "\n"
    "     endif
    " else
    "     let l:content .= "No request found\n"
    " endif
    
"    let l:content .= "\n=== Curl Command ===\n" . vim_restman_curl_builder#FormatCurlCommand(a:curl_command) . "\n"
    let l:content .= "\n=== Curl Output ===\n" . s:PrettyPrintJson(a:output)

    if !empty(a:updated_captures)
        let l:content .= "\n=== Captured Variables ===\n"
        for [key, value] in items(a:updated_captures)
            let l:content .= key . ": " . string(value) . "\n"
        endfor
    endif

    return l:content
endfunction


function! s:SetupSyntaxHighlighting()
    if has('syntax') && exists('g:syntax_on')
        " Clear any existing syntax
        syntax clear

        " Define syntax for headers
        syntax match RestManHeader /^=== [^=]\+ ===$/ 

        " Define syntax region for Curl Output
        syntax region RestManCurlOutput start=/^=== Curl Output ===$/hs=e+1 end=/\%$/ contains=RestManJson,RestManJsonKeyValue

        " Define JSON syntax within Curl Output
        syntax region RestManJson start=/{/ end=/}/ contained contains=RestManJson,RestManJsonKeyValue fold
        syntax match RestManJsonKeyValue /"\zs\w\+\ze":/ contained

        " Set highlighting colors
        highlight RestManHeader ctermfg=121 guifg=#98FB98
        highlight RestManJsonKeyValue ctermfg=81 guifg=#5fd7ff
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

function! vim_restman_buffer_manager#SetRestManBufferNumber(bufnr)
    let s:restman_bufnr = a:bufnr
endfunction

