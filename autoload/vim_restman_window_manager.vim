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

function! vim_restman_window_manager#SaveOriginalState()
    let s:original_winid = win_getid()
    let s:original_bufnr = bufnr('%')
    echom "Original window ID: " . s:original_winid
    echom "Original buffer number: " . s:original_bufnr
endfunction

function! vim_restman_window_manager#ReturnToOriginalWindow()
    if win_gotoid(s:original_winid)
        echom "Returned to original window"
    else
        echom "Failed to return to original window"
    endif
endfunction


function! vim_restman_window_manager#CreateOrUpdateRestManWindow()
    let l:existing_winid = s:FindRestManWindow()
    if l:existing_winid != 0
        call win_gotoid(l:existing_winid)
        echom "Switched to existing RestMan window"
    else
        vsplit
        enew
        setlocal buftype=nofile
        setlocal bufhidden=hide
        setlocal noswapfile
        file RestMan
    endif
    let s:restman_bufnr = bufnr('%')
    let s:restman_winid = win_getid()
    echom "RestMan window ID: " . s:restman_winid
    echom "RestMan buffer number: " . s:restman_bufnr
endfunction

function! s:FindRestManWindow()
    for l:winid in range(1, winnr('$'))
        if bufname(winbufnr(l:winid)) =~ '^RestMan'
            return win_getid(l:winid)
        endif
    endfor
    return 0
endfunction


function! vim_restman_window_manager#GetRestManBufferNumber()
    return s:restman_bufnr
endfunction

function! s:FindRestManWindow()
    for l:winid in range(1, winnr('$'))
        if bufname(winbufnr(l:winid)) == 'RestMan'
            return win_getid(l:winid)
        endif
    endfor
    return 0
endfunction

function! vim_restman_window_manager#CloseRestManWindow()
    let l:restman_winid = s:FindRestManWindow()
    if l:restman_winid != 0
        call win_gotoid(l:restman_winid)
        close
        echom "Closed RestMan window"
    else
        echom "RestMan window not found"
    endif
endfunction

function! vim_restman_window_manager#LogWindowLayout()
    echom "Current window layout: " . s:GetWindowLayout()
    echom "Current buffer list: " . s:GetBufferList()
endfunction

function! s:GetWindowLayout()
    let l:layout = ""
    for i in range(1, winnr('$'))
        let l:bufname = bufname(winbufnr(i))
        let l:winid = win_getid(i)
        let l:layout .= "Win" . i . " (ID:" . l:winid . "):" . l:bufname . " | "
    endfor
    return l:layout
endfunction

function! s:GetBufferList()
    let l:buflist = ""
    for i in range(1, bufnr('$'))
        if buflisted(i)
            let l:buflist .= "Buf" . i . ":" . bufname(i) . " | "
        endif
    endfor
    return l:buflist
endfunction

