" autoload/vim_restman.vim

" Global Variables
let s:original_winid = 0
let s:original_bufnr = 0
let s:restman_winid = 0
let s:restman_bufnr = 0

function! vim_restman#Main()
    echom "vim_restman#Main() called"
    
    if !vim_restman_utils#IsRestFile()
        echom "Not a .rest file, exiting"
        return
    endif

    call vim_restman_window_manager#SaveOriginalState()

    let l:parsed_data = vim_restman_file_parser#ParseCurrentFile()
    let l:request_index = vim_restman_utils#GetRequestIndexFromCursor(l:parsed_data)
    let l:curl_command = vim_restman_curl_builder#BuildCurlCommand(l:parsed_data, l:request_index)
    let l:output = vim_restman_curl_builder#ExecuteCurlCommand(l:curl_command)

    call vim_restman_window_manager#CreateOrUpdateRestManWindow()
    call vim_restman_buffer_manager#PopulateRestManBuffer(l:parsed_data, l:curl_command, l:output, l:request_index)
    
    call vim_restman_window_manager#ReturnToOriginalWindow()
    echom "Returned to original window"
endfunction

