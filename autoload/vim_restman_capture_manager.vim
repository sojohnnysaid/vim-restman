" autoload/vim_restman_capture_manager.vim

" Global variable to store captured values
if !exists("g:vim_restman_captures")
    let g:vim_restman_captures = {}
endif

function! vim_restman_capture_manager#DeclareCaptureVariable(var_name)
    let g:vim_restman_captures[a:var_name] = ''
endfunction

function! vim_restman_capture_manager#UpdateCapturedValue(var_name, value)
    if has_key(g:vim_restman_captures, a:var_name)
        let g:vim_restman_captures[a:var_name] = a:value
    endif
endfunction

function! vim_restman_capture_manager#GetCapturedValue(var_name)
    return get(g:vim_restman_captures, a:var_name, '')
endfunction

function! vim_restman_capture_manager#ProcessJsonResponse(json_response)
    let l:json_obj = json_decode(a:json_response)
    let l:updated_captures = {}
    if type(l:json_obj) == v:t_dict
        for [key, value] in items(g:vim_restman_captures)
            if has_key(l:json_obj, key)
                call vim_restman_capture_manager#UpdateCapturedValue(key, l:json_obj[key])
                let l:updated_captures[key] = l:json_obj[key]
            endif
        endfor
    endif
    return l:updated_captures
endfunction

function! vim_restman_capture_manager#SubstituteCapturedValues(text)
    let l:result = a:text
    for [key, value] in items(g:vim_restman_captures)
        let l:result = substitute(l:result, ':' . key, value, 'g')
    endfor
    return l:result
endfunction

function! vim_restman_capture_manager#GetAllCapturedValues()
    return g:vim_restman_captures
endfunction

" Function to clear all captured values
function! vim_restman_capture_manager#ClearAllCapturedValues()
    let g:vim_restman_captures = {}
endfunction

