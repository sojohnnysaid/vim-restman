" autoload/vim_restman_file_parser.vim

function! vim_restman_file_parser#ParseCurrentFile()
    echom "vim_restman_file_parser#ParseCurrentFile() called"
    let l:captured_text = s:CaptureBetweenDelimiters('#Globals Start', '#Requests End')
    return s:ParseCapturedText(l:captured_text)
endfunction

function! s:CaptureBetweenDelimiters(start_delimiter, end_delimiter)
    let l:start_line = search(a:start_delimiter, 'n')
    let l:end_line = search(a:end_delimiter, 'n')
    let l:captured_text = getline(l:start_line, l:end_line)
    echom "Captured text between delimiters: " . string(l:captured_text)
    return l:captured_text
endfunction



function! s:ParseCapturedText(captured_text)
    echom "s:ParseCapturedText() called"
    let l:parsed_data = {
        \ 'globals': {},
        \ 'requests': []
    \ }
    let l:current_section = ''
    let l:current_key = ''
    let l:current_request = {}

    echom "Parsing Globals:"
    for line in a:captured_text
        let l:trimmed_line = trim(line)
        if empty(l:trimmed_line)
            continue
        endif

        if l:trimmed_line =~ '^#Globals Start'
            let l:current_section = 'globals'
            echom "  Entering globals section"
        elseif l:trimmed_line =~ '^#Requests Start'
            let l:current_section = 'requests'
            echom "Entering requests section"
        elseif l:trimmed_line =~ '^#'
            continue
        elseif l:current_section == 'globals'
            if l:trimmed_line =~ '^@'
                let l:current_key = l:trimmed_line[1:]
                let l:parsed_data.globals[l:current_key] = ''
                echom "  New global key: " . l:current_key
            else
                if l:current_key == 'variables'
                    echom "    Variable: " . l:trimmed_line
                elseif l:current_key == 'capture'
                    echom "    Capture: " . l:trimmed_line
                    call vim_restman_capture_manager#DeclareCaptureVariable(trim(l:trimmed_line))
                endif
                let l:parsed_data.globals[l:current_key] .= (empty(l:parsed_data.globals[l:current_key]) ? '' : "\n") . l:trimmed_line
            endif
        elseif l:current_section == 'requests'
            if l:trimmed_line == '--'
                if !empty(l:current_request)
                    call add(l:parsed_data.requests, l:current_request)
                    echom "Added request: " . string(l:current_request)
                    let l:current_request = {}
                endif
            elseif l:trimmed_line =~ '^\(GET\|POST\|PUT\|DELETE\|PATCH\)'
                let [l:method, l:endpoint] = split(l:trimmed_line, ' ')
                let l:current_request = {'method': l:method, 'endpoint': l:endpoint, 'headers': '', 'body': ''}
                echom "New request: " . l:method . " " . l:endpoint
            elseif l:trimmed_line =~ '^[A-Za-z-]\+:'
                let l:current_request.headers .= l:trimmed_line . "\n"
                echom "Added header to request: " . l:trimmed_line
            elseif !empty(l:current_request)
                let l:current_request.body .= l:trimmed_line . "\n"
                echom "Added to request body: " . l:trimmed_line
            endif
        endif
    endfor

    if !empty(l:current_request)
        call add(l:parsed_data.requests, l:current_request)
        echom "Added final request: " . string(l:current_request)
    endif

    for key in keys(l:parsed_data.globals)
        let l:parsed_data.globals[key] = trim(l:parsed_data.globals[key])
        echom "Trimmed global key " . key . ": " . l:parsed_data.globals[key]
    endfor

    " Process variables
    if has_key(l:parsed_data.globals, 'variables')
        let l:variables_dict = s:ParseVariables(l:parsed_data.globals.variables)
        let l:parsed_data.globals.variables = l:variables_dict
        echom "Processed variables: " . string(l:variables_dict)
    endif

    echom "Final parsed data: " . string(l:parsed_data)
    return l:parsed_data
endfunction



function! s:ParseVariables(variables_string)
    let l:variables_dict = {}
    for var_line in split(a:variables_string, "\n")
        let l:parts = split(var_line, '=')
        if len(l:parts) == 2
            let [var_name, var_value] = l:parts
            let l:variables_dict[trim(var_name)] = trim(var_value)
            echom "Parsed variable: " . trim(var_name) . " = " . trim(var_value)
        else
            echom "Invalid variable format: " . var_line
        endif
    endfor
    return l:variables_dict
endfunction

