" vim-restman test runner
" This is a simple test runner for vim-restman

" Setup environment
let s:test_dir = expand('<sfile>:p:h')
let s:plugin_dir = fnamemodify(s:test_dir, ':h')
let s:test_count = 0
let s:test_passed = 0
let s:test_failed = 0

" Enable debug mode
let g:vim_restman_debug = 1

" Source all plugin files
execute 'source ' . s:plugin_dir . '/plugin/vim-restman.vim'
for file in glob(s:plugin_dir . '/autoload/*.vim', 0, 1)
    execute 'source ' . file
endfor

" Load test files
for test_file in glob(s:test_dir . '/test_*.vim', 0, 1)
    execute 'source ' . test_file
endfor

" Assertion functions
function! s:assert_equal(expected, actual, message)
    let s:test_count += 1
    if a:expected ==# a:actual
        let s:test_passed += 1
        echo '[PASS] ' . a:message
    else
        let s:test_failed += 1
        echohl ErrorMsg
        echo '[FAIL] ' . a:message
        echo '       Expected: ' . string(a:expected)
        echo '       Actual:   ' . string(a:actual)
        echohl None
    endif
endfunction

function! s:assert_true(condition, message)
    call s:assert_equal(1, a:condition ? 1 : 0, a:message)
endfunction

function! s:assert_false(condition, message)
    call s:assert_equal(0, a:condition ? 1 : 0, a:message)
endfunction

function! s:assert_match(pattern, string, message)
    let s:test_count += 1
    if a:string =~ a:pattern
        let s:test_passed += 1
        echo '[PASS] ' . a:message
    else
        let s:test_failed += 1
        echohl ErrorMsg
        echo '[FAIL] ' . a:message
        echo '       String "' . a:string . '" does not match pattern "' . a:pattern . '"'
        echohl None
    endif
endfunction

" Register test functions
let s:test_functions = []

function! RegisterTest(name, function)
    call add(s:test_functions, {'name': a:name, 'function': a:function})
endfunction

" Run tests
echo "Running vim-restman tests..."
let s:start_time = reltime()

for test in s:test_functions
    echo "\nRunning test: " . test.name
    echo "----------------------------------------"
    try
        call test.function()
    catch
        let s:test_failed += 1
        echohl ErrorMsg
        echo '[ERROR] Test "' . test.name . '" threw an exception:'
        echo '        ' . v:exception . ' at ' . v:throwpoint
        echohl None
    endtry
endfor

let s:elapsed = reltimefloat(reltime(s:start_time))

" Summary
echo "\n----------------------------------------"
echo "Test summary:"
echo "  Total tests: " . s:test_count
echo "  Passed:      " . s:test_passed
echo "  Failed:      " . s:test_failed
echo "  Time:        " . printf("%.2f seconds", s:elapsed)

if s:test_failed == 0
    echo "\n[SUCCESS] All tests passed!"
else
    echohl ErrorMsg
    echo "\n[FAILURE] Some tests failed!"
    echohl None
endif