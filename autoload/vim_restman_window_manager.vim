" autoload/vim_restman_window_manager.vim

" Global Variables
if !exists("s:original_winid")
    let s:original_winid = 0
endif

if !exists("s:original_bufnr")
    let s:original_bufnr = 0
endif

if !exists("s:restman_winid")
    let s:restman_winid = 0
endif

if !exists("s:restman_bufnr")
    let s:restman_bufnr = 0
endif

" Save the original window state to return to later
" Stores window ID and buffer number
function! vim_restman_window_manager#SaveOriginalState()
    let s:original_winid = win_getid()
    let s:original_bufnr = bufnr('%')
    call vim_restman_utils#LogDebug("Saved original state - Window ID: " . s:original_winid . ", Buffer: " . s:original_bufnr)
endfunction

" Return to the original window
" Uses the stored window ID
function! vim_restman_window_manager#ReturnToOriginalWindow()
    if win_gotoid(s:original_winid)
        call vim_restman_utils#LogDebug("Returned to original window")
    else
        call vim_restman_utils#LogWarning("Failed to return to original window")
    endif
endfunction

" Create a new RestMan window or update an existing one
" This function handles both creating a new window or reusing an existing one
function! vim_restman_window_manager#CreateOrUpdateRestManWindow()
    call vim_restman_utils#LogDebug("Creating or updating RestMan window")
    
    " Check for an existing RestMan buffer
    let l:restman_buffers = getbufinfo({'bufloaded': 1})
    let l:restman_bufnr = -1
    
    " Find any buffer with RestMan in the name
    for buf in l:restman_buffers
        if buf.name =~ 'RestMan'
            let l:restman_bufnr = buf.bufnr
            call vim_restman_utils#LogDebug("Found existing RestMan buffer: " . l:restman_bufnr)
            break
        endif
    endfor
    
    " If we found a RestMan buffer
    if l:restman_bufnr != -1
        " Check if there's a window displaying this buffer
        let l:win_ids = win_findbuf(l:restman_bufnr)
        
        if !empty(l:win_ids)
            " Window exists, focus it
            call win_gotoid(l:win_ids[0])
            call vim_restman_utils#LogDebug("Switched to existing RestMan window " . l:win_ids[0])
        else
            " Create a window for the existing buffer
            execute 'vsplit'
            execute 'buffer ' . l:restman_bufnr
            call vim_restman_utils#LogDebug("Created new window for existing RestMan buffer " . l:restman_bufnr)
        endif
    else
        " No RestMan buffer exists, create a new one
        execute 'vsplit'
        enew
        setlocal buftype=nofile
        setlocal bufhidden=hide
        setlocal noswapfile
        
        " Generate a unique buffer name with timestamp
        let l:timestamp = strftime('%H%M%S')
        let l:buffer_name = 'RestMan_' . l:timestamp
        
        " Set the buffer name
        execute 'file ' . l:buffer_name
        call vim_restman_utils#LogDebug("Created buffer named " . l:buffer_name)
    endif
    
    " Update the buffer to nomodified state
    setlocal nomodified
    
    " Update global variables
    let s:restman_bufnr = bufnr('%')
    let s:restman_winid = win_getid()
    call vim_restman_utils#LogInfo("Active RestMan window: " . s:restman_winid . ", Buffer: " . s:restman_bufnr)
endfunction

" Get the RestMan buffer number
" @return {number} The buffer number
function! vim_restman_window_manager#GetRestManBufferNumber()
    return s:restman_bufnr
endfunction

" Close the RestMan window if it exists
function! vim_restman_window_manager#CloseRestManWindow()
    let l:win_ids = win_findbuf(s:restman_bufnr)
    
    if !empty(l:win_ids)
        call win_gotoid(l:win_ids[0])
        close
        call vim_restman_utils#LogDebug("Closed RestMan window")
    else
        call vim_restman_utils#LogDebug("RestMan window not found")
    endif
endfunction

" Log the current window layout for debugging
function! vim_restman_window_manager#LogWindowLayout()
    call vim_restman_utils#LogDebug("Current window layout: " . s:GetWindowLayout())
    call vim_restman_utils#LogDebug("Current buffer list: " . s:GetBufferList())
endfunction

" Helper function to get window layout as a string
" @return {string} Description of window layout
function! s:GetWindowLayout()
    let l:layout = ""
    for i in range(1, winnr('$'))
        let l:bufname = bufname(winbufnr(i))
        let l:winid = win_getid(i)
        let l:layout .= "Win" . i . " (ID:" . l:winid . "):" . l:bufname . " | "
    endfor
    return l:layout
endfunction

" Helper function to get buffer list as a string
" @return {string} Description of buffer list
function! s:GetBufferList()
    let l:buflist = ""
    for i in range(1, bufnr('$'))
        if buflisted(i)
            let l:buflist .= "Buf" . i . ":" . bufname(i) . " | "
        endif
    endfor
    return l:buflist
endfunction