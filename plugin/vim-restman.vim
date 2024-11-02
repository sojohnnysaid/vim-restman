" vim_restman.vim - RestMan Plugin for Vim
" Author:       Your Name
" Version:      1.0

if exists("g:loaded_vim_restman")
    finish
endif
let g:loaded_vim_restman = 1

" Check if Vim is in compatible mode
if &compatible
    echo "vim_restman: This plugin requires 'nocompatible' mode. Add 'set nocompatible' to your .vimrc"
    finish
endif

" Define default mappings if they don't exist
if !hasmapto('<Plug>RestManMain')
    nmap <unique> <C-i> <Plug>RestManMain
endif

" Define <Plug> mapping
nnoremap <unique> <script> <Plug>RestManMain <SID>Main
nnoremap <SID>Main :call vim_restman#Main()<CR>

" Define commands
command! -nargs=0 RestManMain call vim_restman#Main()

" Include all the function definitions here
" (s:IsRestFile, s:ParseCurrentFile, s:CaptureBetweenDelimiters, s:ParseCapturedText, 
" s:GetRequestIndexFromCursor, s:BuildCurlCommand, s:ExecuteCurlCommand, 
" s:CreateRestManWindow, s:PopulateRestManBuffer)

" You can add more configuration options or default settings here

" vim:set ft=vim et sw=4:

