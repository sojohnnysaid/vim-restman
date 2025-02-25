" autoload/vim_restman.vim
" Main module for the vim-restman plugin

" Global variable to track the results buffer
if !exists('g:vim_restman_results_buffer')
    let g:vim_restman_results_buffer = -1
endif

" Main function - entry point for the plugin
" @param {boolean} return_to_original - Whether to return to the original window after execution
function! vim_restman#Main(...)
    " Get optional parameter with default value
    let l:return_to_original = get(a:, 1, 1)
    
    call vim_restman_utils#LogInfo("RestMan plugin started")
    
    " Validate file type
    if !s:ValidateFile()
        return 0
    endif
    
    " Process the request file
    let l:parsed_data = vim_restman_file_parser#ParseCurrentFile()
    
    " Initialize variables
    call s:InitializeVariables(l:parsed_data)
    
    " Get the request index based on cursor position
    let l:request_index = vim_restman_utils#GetRequestIndexFromCursor(l:parsed_data)
    
    if l:request_index < 0
        call vim_restman_utils#LogError("No request found at cursor position")
        return 0
    endif
    
    " Execute the request
    let l:success = vim_restman_execute#ExecuteRequest(l:parsed_data, l:request_index)
    
    return l:success
endfunction

" Validate that the current file is a .rest file
" @return {boolean} True if valid, False otherwise
function! s:ValidateFile()
    if !vim_restman_utils#IsRestFile()
        call vim_restman_utils#LogError("Not a .rest file")
        return 0
    endif
    return 1
endfunction

" Initialize variables from parsed data
" @param {dict} parsed_data - The parsed file data
function! s:InitializeVariables(parsed_data)
    " Initialize variable store
    call vim_restman_store#Initialize()
    
    " Process global variables from @variables section
    if has_key(a:parsed_data.globals, 'variables')
        call s:ProcessVariables(a:parsed_data.globals.variables)
    endif
    
    " Process capture declarations from @capture section
    if has_key(a:parsed_data.globals, 'capture')
        call s:ProcessCaptureDeclarations(a:parsed_data.globals.capture)
    endif
endfunction

" Process and initialize variables
" @param {string|dict} variables - Variables section data
function! s:ProcessVariables(variables)
    " Handle dictionary format (already parsed)
    if type(a:variables) == v:t_dict
        for [var_name, var_value] in items(a:variables)
            call vim_restman_store#SetVariable(var_name, var_value, 1)
        endfor
        return
    endif
    
    " Handle string format (needs parsing)
    if type(a:variables) == v:t_string
        for var_line in split(a:variables, "\n")
            let l:parts = split(var_line, '=')
            if len(l:parts) == 2
                let [var_name, var_value] = l:parts
                let var_name = trim(var_name)
                let var_value = trim(var_value)
                
                " Handle environment variables
                if var_value =~ '^\$'
                    let var_value = eval('$' . var_value[1:])
                endif
                
                call vim_restman_store#SetVariable(var_name, var_value, 1)
            endif
        endfor
    endif
endfunction

" Process capture declarations
" @param {string} capture_section - Capture section content
function! s:ProcessCaptureDeclarations(capture_section)
    for capture_var in split(a:capture_section, "\n")
        let capture_var = trim(capture_var)
        call vim_restman_store#SetVariable(capture_var, '', 0)
    endfor
endfunction

" List all request result buffers
function! vim_restman#ListResultBuffers()
    let l:buffers = vim_restman_buffer#ListResultBuffers()
    
    if empty(l:buffers)
        call vim_restman_utils#LogInfo("No request result buffers found")
        return []
    endif
    
    " Display buffer list
    echo "RestMan Result Buffers:"
    echo "----------------------"
    let l:i = 0
    for buffer in l:buffers
        echo l:i . ": " . buffer.name . " - " . buffer.method . " " . buffer.endpoint
        let l:i += 1
    endfor
    
    return l:buffers
endfunction

" Navigate to a specific result buffer
" @param {number} index - The buffer index
" @return {boolean} Success status
function! vim_restman#NavigateToBuffer(index)
    return vim_restman_buffer#NavigateToBuffer(a:index)
endfunction

" Close all result buffers
function! vim_restman#CloseAllResultBuffers()
    call vim_restman_buffer#CloseAllResultBuffers()
endfunction

" Clean up resources used by the plugin
function! vim_restman#CleanUp()
    " Close result buffers
    call vim_restman#CloseAllResultBuffers()
    
    " Reset the results buffer tracking
    let g:vim_restman_results_buffer = -1
    
    call vim_restman_utils#LogInfo("RestMan plugin cleaned up")
endfunction

" Reload the plugin (useful for development)
function! vim_restman#ReloadPlugin()
    call vim_restman#CleanUp()
    runtime! autoload/vim_restman*.vim
    call vim_restman_utils#LogInfo("RestMan plugin reloaded")
endfunction

" Initialize the plugin with commands and settings
function! vim_restman#InitPlugin()
    " Define or redefine commands
    command! -nargs=0 RestManExec call vim_restman#Main()
    command! -nargs=0 RestManList call vim_restman#ListResultBuffers()
    command! -nargs=1 RestManGoto call vim_restman#NavigateToBuffer(<args>)
    command! -nargs=0 RestManCloseAll call vim_restman#CloseAllResultBuffers()
    command! -nargs=0 RestManDebugOn let g:vim_restman_debug = 1 | echo "RestMan debug mode enabled"
    command! -nargs=0 RestManDebugOff let g:vim_restman_debug = 0 | echo "RestMan debug mode disabled"
    command! -nargs=0 RestManReload call vim_restman#ReloadPlugin()
    command! -nargs=0 RestManBufferInfo call vim_restman#DisplayBufferInfo()
    
    " For backward compatibility
    command! -nargs=0 RestManMain call vim_restman#Main()
    
    " Initialize global debug flag if not already set
    if !exists('g:vim_restman_debug')
        let g:vim_restman_debug = 0
    endif
    
    echo "RestMan plugin initialized. Use :RestManExec to execute a request at cursor position."
endfunction

" Display debug information about buffers
function! vim_restman#DisplayBufferInfo()
    echo "RestMan Buffer Information:"
    echo "-------------------------"
    echo "Result buffer tracking: " . g:vim_restman_results_buffer
    echo "Current buffer: " . bufnr('%') . " - " . bufname('%')
    echo "Debug mode: " . (g:vim_restman_debug ? "ON" : "OFF")
    echo ""
    echo "Window layout:"
    for i in range(1, winnr('$'))
        let l:bufnr = winbufnr(i)
        let l:bufname = bufname(l:bufnr)
        let l:winid = win_getid(i)
        echo "  Window " . i . " (ID:" . l:winid . "): Buffer " . l:bufnr . " - " . l:bufname
    endfor
    echo ""
    echo "Listed buffers:"
    for buf in getbufinfo({'buflisted': 1})
        echo "  Buffer " . buf.bufnr . ": " . buf.name . (buf.loaded ? " (loaded)" : " (not loaded)")
    endfor
endfunction