" autoload/vim_restman.vim

" Global Variables
let s:original_winid = 0
let s:original_bufnr = 0
let s:restman_winid = 0
let s:restman_bufnr = 0

" Global variable tracking structure
let s:variables = {}



function! vim_restman#Main()
    #echom "vim_restman#Main() called"
    
    if !vim_restman_utils#IsRestFile()
        #echom "Not a .rest file, exiting"
        return
    endif

    call vim_restman_window_manager#SaveOriginalState()

    let l:parsed_data = vim_restman_file_parser#ParseCurrentFile()
    #echom "Parsed data: " . string(l:parsed_data)

    call s:InitializeVariables(l:parsed_data)
    #echom "Initialized variables: " . string(s:variables)

    if empty(l:parsed_data.requests)
        #echom "No request found at cursor position"
        return
    endif

    #echom "Captured values before request: " . string(vim_restman_capture_manager#GetAllCapturedValues())

    let l:curl_command = vim_restman_curl_builder#BuildCurlCommand(l:parsed_data, s:variables)
    #echom "Built curl command: " . l:curl_command

    let [l:output, l:updated_captures] = vim_restman_curl_builder#ExecuteCurlCommand(l:curl_command)
    #echom "Curl output: " . l:output
    #echom "Updated captures: " . string(l:updated_captures)

    call s:UpdateVariables(l:updated_captures)
    #echom "Updated variables: " . string(s:variables)
    #echom "Captured values after request: " . string(vim_restman_capture_manager#GetAllCapturedValues())

    call vim_restman_window_manager#CreateOrUpdateRestManWindow()
    let s:restman_winid = win_getid()
    let s:restman_bufnr = bufnr('%')
    call vim_restman_buffer_manager#SetRestManBufferNumber(s:restman_bufnr)
    
    call vim_restman_buffer_manager#PopulateRestManBuffer(l:parsed_data, l:curl_command, l:output, l:updated_captures, s:variables)
    
    call vim_restman_window_manager#ReturnToOriginalWindow()
    #echom "Returned to original window"

    " Log final state of captured values and variables
    #echom "Final captured values: " . string(vim_restman_capture_manager#GetAllCapturedValues())
    #echom "Final variables: " . string(s:variables)
endfunction






function! s:InitializeVariables(parsed_data)
    " Initialize s:variables if it doesn't exist
    if !exists('s:variables')
        let s:variables = {}
    endif

    #echom "Initializing variables:"
    " Update or add variables from @variables section
    if has_key(a:parsed_data.globals, 'variables')
        for [var_name, var_value] in items(a:parsed_data.globals.variables)
            let var_value = trim(var_value)
            if var_value =~ '^\$'
                let env_var_name = var_value[1:]
                let var_value = exists('$' . env_var_name) ? eval('$' . env_var_name) : ''
                #echom "  Fetching environment variable: " . env_var_name . " = " . var_value
            endif
            let s:variables[var_name] = {'value': var_value, 'set': !empty(var_value)}
            #echom "  Initialized variable: " . var_name . " = " . var_value . " (set: " . !empty(var_value) . ")"
        endfor
    endif

    #echom "Initializing capture variables:"
    " Update or add capture variables
    if has_key(a:parsed_data.globals, 'capture')
        for capture_var in split(a:parsed_data.globals.capture, "\n")
            let capture_var = trim(capture_var)
            " Only update if not already set
            if !has_key(s:variables, capture_var) || empty(s:variables[capture_var].value)
                let captured_value = vim_restman_capture_manager#GetCapturedValue(capture_var)
                let s:variables[capture_var] = {'value': captured_value, 'set': !empty(captured_value)}
                #echom "  Initialized capture variable: " . capture_var . " = " . captured_value . " (set: " . !empty(captured_value) . ")"
            else
                #echom "  Preserved existing variable: " . capture_var . " = " . s:variables[capture_var].value
            endif
        endfor
    endif

    #echom "All initialized variables: " . string(s:variables)
endfunction






function! s:UpdateVariables(updated_captures)
    for [var_name, var_value] in items(a:updated_captures)
        let s:variables[var_name] = {'value': var_value, 'set': 1}
        #echom "Updated variable: " . var_name . " = " . var_value . " (set: 1)"
        " Also update the captured value in the capture manager
        call vim_restman_capture_manager#UpdateCapturedValue(var_name, var_value)
    endfor
endfunction








function! vim_restman#GetVariables()
    return s:variables
endfunction

function! vim_restman#CleanUp()
    call vim_restman_buffer_manager#ClearRestManBuffer()
    call vim_restman_capture_manager#ClearAllCapturedValues()
    let s:restman_winid = 0
    let s:restman_bufnr = 0
    let s:variables = {}
    #echom "RestMan cleaned up"
endfunction

function! vim_restman#GetRestManWindowID()
    return s:restman_winid
endfunction

function! vim_restman#GetRestManBufferNumber()
    return s:restman_bufnr
endfunction

function! vim_restman#GetOriginalWindowID()
    return s:original_winid
endfunction

function! vim_restman#GetOriginalBufferNumber()
    return s:original_bufnr
endfunction

function! vim_restman#SetOriginalState(winid, bufnr)
    let s:original_winid = a:winid
    let s:original_bufnr = a:bufnr
    #echom "Set original state - Window ID: " . a:winid . ", Buffer: " . a:bufnr
endfunction

function! vim_restman#ReloadPlugin()
    call vim_restman#CleanUp()
    runtime! autoload/vim_restman*.vim
    #echom "RestMan plugin reloaded"
endfunction

