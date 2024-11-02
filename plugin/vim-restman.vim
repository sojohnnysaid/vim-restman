" Title:        Vim RestMan
" Description:  A REST client plugin for Vim
" Last Change:  2023-05-28
" Maintainer:   Your Name <your.email@example.com>

if exists("g:loaded_vim_restman")
    finish
endif
let g:loaded_vim_restman = 1

" Exposes the plugin's functions for use as commands in Vim.
command! -nargs=0 RestManCapture call vim_restman#CaptureAndPrintText()

" Map Ctrl+j (lowercase) to the capture and print function
nnoremap <silent> <C-j> :call vim_restman#CaptureAndPrintText()<CR>

