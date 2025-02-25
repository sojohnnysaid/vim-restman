" vim-restman.vim - RestMan Plugin for Vim
" Author:       John Hargrove
" Version:      2.0
" Description:  A REST client for Vim with buffer-per-request approach

if exists("g:loaded_vim_restman")
    finish
endif
let g:loaded_vim_restman = 1

" Check if Vim is in compatible mode
if &compatible
    echo "vim-restman: This plugin requires 'nocompatible' mode. Add 'set nocompatible' to your .vimrc"
    finish
endif

" Global configuration options
if !exists('g:vim_restman_debug')
    let g:vim_restman_debug = 0
endif

if !exists('g:vim_restman_split_direction')
    let g:vim_restman_split_direction = 'vertical'  " or 'horizontal'
endif

if !exists('g:vim_restman_split_size')
    let g:vim_restman_split_size = 80  " width or height depending on split direction
endif

if !exists('g:vim_restman_max_history')
    let g:vim_restman_max_history = 20  " maximum number of requests to keep in history
endif

if !exists('g:vim_restman_verbose_output')
    let g:vim_restman_verbose_output = 0  " 0 = minimal output, 1 = verbose output
endif

" Define default mappings if they don't exist
if !hasmapto('<Plug>RestManExec')
    nmap <unique> <C-i> <Plug>RestManExec
endif

" Define <Plug> mapping
nnoremap <unique> <script> <Plug>RestManExec <SID>Exec
nnoremap <SID>Exec :call vim_restman#Main()<CR>

" Define commands
if !exists(":RestManExec")
    command -nargs=0 RestManExec call vim_restman#Main()
endif

if !exists(":RestManList")
    command -nargs=0 RestManList call vim_restman#ListResultBuffers()
endif

if !exists(":RestManGoto")
    command -nargs=1 RestManGoto call vim_restman#NavigateToBuffer(<args>)
endif

if !exists(":RestManCloseAll")
    command -nargs=0 RestManCloseAll call vim_restman#CloseAllResultBuffers()
endif

if !exists(":RestManDebugOn")
    command -nargs=0 RestManDebugOn let g:vim_restman_debug = 1 | echo "RestMan debug mode enabled"
endif

if !exists(":RestManDebugOff")
    command -nargs=0 RestManDebugOff let g:vim_restman_debug = 0 | echo "RestMan debug mode disabled"
endif

if !exists(":RestManVerboseOn")
    command -nargs=0 RestManVerboseOn let g:vim_restman_verbose_output = 1 | echo "RestMan verbose output enabled"
endif

if !exists(":RestManVerboseOff")
    command -nargs=0 RestManVerboseOff let g:vim_restman_verbose_output = 0 | echo "RestMan verbose output disabled"
endif

if !exists(":RestManReload")
    command -nargs=0 RestManReload call vim_restman#ReloadPlugin()
endif

" For backward compatibility
if !exists(":RestManMain")
    command -nargs=0 RestManMain call vim_restman#Main()
endif

" Check for required dependencies
if !executable('curl')
    echohl WarningMsg
    echom "RestMan: curl is not installed or not in your PATH. The plugin requires curl for making HTTP requests."
    echohl None
endif

if !executable('jq')
    echohl WarningMsg
    echom "RestMan: jq is not installed or not in your PATH. JSON formatting will be limited."
    echohl None
endif

" vim:set ft=vim et sw=4: