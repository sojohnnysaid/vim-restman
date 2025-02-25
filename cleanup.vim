" Cleanup script to reset Vim's state
" Run this before testing if you're having issues

" Close all buffers
silent! %bwipeout!

" Reset variables
let g:vim_restman_debug = 0
let g:vim_restman_loaded = 0

" Clear message history
messages clear

echo "Cleanup complete. Use :source init.vim to reload the plugin."