" autoload/vim_restman_file_parser.vim

function! vim_restman_file_parser#ParseCurrentFile()
    " echom "vim_restman_file_parser#ParseCurrentFile() called"
    let l:globals = s:CaptureBetweenDelimiters('#Globals Start', '#Globals End')
    let l:current_request = s:CaptureCurrentRequest()
    return s:ParseCapturedText(l:globals, l:current_request)
endfunction

function! s:CaptureBetweenDelimiters(start_delimiter, end_delimiter)
    let l:start_line = search(a:start_delimiter, 'n')
    let l:end_line = search(a:end_delimiter, 'n')
    let l:captured_text = getline(l:start_line, l:end_line)
    " echom "Captured text between delimiters: " . string(l:captured_text)
    return l:captured_text
endfunction

function! s:CaptureCurrentRequest()
    let l:cursor_line = line('.')
    let l:start_line = search('^\s*--\s*$', 'bn')
    let l:end_line = search('^\s*--\s*$', 'n')
    
    if l:start_line == 0 || l:end_line == 0 || l:cursor_line < l:start_line || l:cursor_line > l:end_line
        " echom "No request found at cursor position"
        return []
    endif
    
    let l:captured_request = getline(l:start_line + 1, l:end_line - 1)
    " echom "Captured current request: " . string(l:captured_request)
    return l:captured_request
endfunction

function! s:ParseCapturedText(globals, current_request)
    " echom "s:ParseCapturedText() called"
    let l:parsed_data = {
        \ 'globals': {},
        \ 'requests': []
    \ }

    " Parse globals
    let l:current_key = ''
    for line in a:globals
        let l:trimmed_line = trim(line)
        if empty(l:trimmed_line) || l:trimmed_line =~ '^#'
            continue
        elseif l:trimmed_line =~ '^@'
            let l:current_key = l:trimmed_line[1:]
            let l:parsed_data.globals[l:current_key] = ''
            " echom "  New global key: " . l:current_key
        else
            if l:current_key == 'variables'
                " echom "    Variable: " . l:trimmed_line
            elseif l:current_key == 'capture'
                " echom "    Capture: " . l:trimmed_line
                call vim_restman_capture_manager#DeclareCaptureVariable(trim(l:trimmed_line))
            endif
            let l:parsed_data.globals[l:current_key] .= (empty(l:parsed_data.globals[l:current_key]) ? '' : "\n") . l:trimmed_line
        endif
    endfor

    " Parse current request
    let l:current_request_data = {'method': '', 'endpoint': '', 'headers': '', 'body': ''}
    for line in a:current_request
        let l:trimmed_line = trim(line)
        if empty(l:trimmed_line)
            continue
        elseif l:current_request_data.method == ''
            let [l:current_request_data.method, l:current_request_data.endpoint] = split(l:trimmed_line, ' ')
            " echom "New request: " . l:current_request_data.method . " " . l:current_request_data.endpoint
        elseif l:trimmed_line =~ '^[A-Za-z-]\+:'
            let l:current_request_data.headers .= l:trimmed_line . "\n"
            " echom "Added header to request: " . l:trimmed_line
        else
            let l:current_request_data.body .= l:trimmed_line . "\n"
            " echom "Added to request body: " . l:trimmed_line
        endif
    endfor
    call add(l:parsed_data.requests, l:current_request_data)

    for key in keys(l:parsed_data.globals)
        let l:parsed_data.globals[key] = trim(l:parsed_data.globals[key])
        " echom "Trimmed global key " . key . ": " . l:parsed_data.globals[key]
    endfor

    " Process variables
    if has_key(l:parsed_data.globals, 'variables')
        let l:variables_dict = s:ParseVariables(l:parsed_data.globals.variables)
        let l:parsed_data.globals.variables = l:variables_dict
        " echom "Processed variables: " . string(l:variables_dict)
    endif

    " echom "Final parsed data: " . string(l:parsed_data)
    return l:parsed_data
endfunction

function! s:ParseVariables(variables_string)
    let l:variables_dict = {}
    for var_line in split(a:variables_string, "\n")
        let l:parts = split(var_line, '=')
        if len(l:parts) == 2
            let [var_name, var_value] = l:parts
            let l:variables_dict[trim(var_name)] = trim(var_value)
            " echom "Parsed variable: " . trim(var_name) . " = " . trim(var_value)
        else
            " echom "Invalid variable format: " . var_line
        endif
    endfor
    return l:variables_dict
endfunction

