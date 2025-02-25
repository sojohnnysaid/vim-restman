" RestMan plugin initialization script
" Source this file to load and initialize the plugin without requiring a plugin manager

" Ensure paths are correct - adjust these if needed
let s:plugin_path = expand('<sfile>:p:h')
let s:autoload_path = s:plugin_path . '/autoload'
let s:plugin_file = s:plugin_path . '/plugin/vim-restman.vim'

" Source key files
try
    " First source logging utilities
    execute 'source ' . s:autoload_path . '/vim_restman_utils.vim'
    
    " Then source JSON module
    execute 'source ' . s:autoload_path . '/vim_restman_json.vim'
    
    " Source all other autoload files
    let s:autoload_files = [
                \ 'vim_restman_store.vim',
                \ 'vim_restman_file_parser.vim',
                \ 'vim_restman_curl_builder.vim',
                \ 'vim_restman_buffer.vim',
                \ 'vim_restman_execute.vim',
                \ 'vim_restman.vim',
                \ ]
    
    for file in s:autoload_files
        let s:full_path = s:autoload_path . '/' . file
        if filereadable(s:full_path)
            execute 'source ' . s:full_path
        else
            echohl WarningMsg
            echo "Could not find file: " . s:full_path
            echohl None
        endif
    endfor
    
    " Source the plugin entry point file
    execute 'source ' . s:plugin_file
    
    " Call initialization function
    call vim_restman#InitPlugin()
    
    echo "RestMan plugin loaded successfully"
    echo "Commands:"
    echo "  :RestManExec     - Execute request at cursor position"
    echo "  :RestManList     - List all result buffers"
    echo "  :RestManGoto N   - Go to result buffer N"
    echo "  :RestManCloseAll - Close all result buffers"
    echo "  :RestManDebugOn  - Enable debug logging"
catch
    echohl ErrorMsg
    echo "Error loading RestMan plugin: " . v:exception
    echohl None
endtry