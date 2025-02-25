" Tests for variable substitution functionality

" Test basic variable substitution
function! s:test_basic_variable_substitution()
    let variables = {
        \ 'token': {'value': '12345', 'set': 1},
        \ 'base_url': {'value': 'https://api.example.com', 'set': 1},
        \ 'user_id': {'value': '42', 'set': 1}
    \ }
    
    " Test :var_name format
    let text = 'GET :base_url/users/:user_id'
    let expected = 'GET https://api.example.com/users/42'
    let result = vim_restman_utils#SubstituteVariables(text, variables)
    call s:assert_equal(expected, result, 'Basic substitution with :var_name format')
    
    " Test {{var_name}} format
    let text = 'GET {{base_url}}/users/{{user_id}}'
    let expected = 'GET https://api.example.com/users/42'
    let result = vim_restman_utils#SubstituteVariables(text, variables)
    call s:assert_equal(expected, result, 'Basic substitution with {{var_name}} format')
    
    " Test $var_name format
    let text = 'Authorization: Bearer $token'
    let expected = 'Authorization: Bearer 12345'
    let result = vim_restman_utils#SubstituteVariables(text, variables)
    call s:assert_equal(expected, result, 'Basic substitution with $var_name format')
    
    " Test mixed formats
    let text = 'GET :base_url/users/{{user_id}}?token=$token'
    let expected = 'GET https://api.example.com/users/42?token=12345'
    let result = vim_restman_utils#SubstituteVariables(text, variables)
    call s:assert_equal(expected, result, 'Mixed format substitution')
endfunction

" Test unset variables should not be substituted
function! s:test_unset_variables()
    let variables = {
        \ 'set_var': {'value': 'set_value', 'set': 1},
        \ 'unset_var': {'value': 'unset_value', 'set': 0}
    \ }
    
    let text = ':set_var and :unset_var'
    let expected = 'set_value and :unset_var'
    let result = vim_restman_utils#SubstituteVariables(text, variables)
    call s:assert_equal(expected, result, 'Unset variables should not be substituted')
endfunction

" Test nested JSON variable access
function! s:test_nested_json_variables()
    let variables = {
        \ 'response': {'value': '{"id": 123, "name": "John Doe", "token": "abc456"}', 'set': 1}
    \ }
    
    let text = 'User ID: {{response.id}}, Name: {{response.name}}'
    let expected = 'User ID: 123, Name: John Doe'
    let result = vim_restman_utils#SubstituteVariables(text, variables)
    call s:assert_equal(expected, result, 'Nested JSON variable access')
endfunction

" Register tests
call RegisterTest('Basic Variable Substitution', function('s:test_basic_variable_substitution'))
call RegisterTest('Unset Variables', function('s:test_unset_variables'))
call RegisterTest('Nested JSON Variables', function('s:test_nested_json_variables'))