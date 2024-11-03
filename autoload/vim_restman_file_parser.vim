" autoload/vim_restman_file_parser.vim

function! vim_restman_file_parser#ParseCurrentFile()
    let l:captured_text = s:CaptureBetweenDelimiters('#Globals Start', '#Requests End')
    return s:ParseCapturedText(l:captured_text)
endfunction

function! s:CaptureBetweenDelimiters(start_delimiter, end_delimiter)
    let l:start_line = search(a:start_delimiter, 'n')
    let l:end_line = search(a:end_delimiter, 'n')
    return getline(l:start_line, l:end_line)
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

    for line in a:captured_text
        let l:trimmed_line = trim(line)
        if empty(l:trimmed_line)
            continue
        endif

        if l:trimmed_line =~ '^#Globals Start'
            let l:current_section = 'globals'
        elseif l:trimmed_line =~ '^#Requests Start'
            let l:current_section = 'requests'
        elseif l:trimmed_line =~ '^#'
            continue
        elseif l:current_section == 'globals'
            if l:trimmed_line =~ '^@'
                let l:current_key = l:trimmed_line[1:]
                let l:parsed_data.globals[l:current_key] = ''
            else
                let l:parsed_data.globals[l:current_key] .= (empty(l:parsed_data.globals[l:current_key]) ? '' : ' ') . l:trimmed_line
            endif
        elseif l:current_section == 'requests'
            if l:trimmed_line == '--'
                if !empty(l:current_request)
                    call add(l:parsed_data.requests, l:current_request)
                    let l:current_request = {}
                endif
            elseif l:trimmed_line =~ '^\(GET\|POST\|PUT\|DELETE\|PATCH\)'
                let [l:method, l:endpoint] = split(l:trimmed_line, ' ')
                let l:current_request = {'method': l:method, 'endpoint': l:endpoint, 'body': ''}
            elseif !empty(l:current_request)
                let l:current_request.body .= l:trimmed_line . "\n"
            endif
        endif
    endfor

    if !empty(l:current_request)
        call add(l:parsed_data.requests, l:current_request)
    endif

    for key in keys(l:parsed_data.globals)
        let l:parsed_data.globals[key] = trim(l:parsed_data.globals[key])
    endfor

    echom "Parsed data: " . string(l:parsed_data)
    return l:parsed_data
endfunction

