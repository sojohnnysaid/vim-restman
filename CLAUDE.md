# VIM RESTMAN DEVELOPMENT GUIDE

## Commands
- Run all tests: `:RestManRunTests`
- Run single test: `:source test/test_file.vim` then call the test function
- Run plugin: `:RestManMain` or press `<C-i>` in a `.rest` file
- Debug logging: `let g:vim_restman_debug = 1`
- Reload plugin: `:call vim_restman#ReloadPlugin()`

## Code Style
- **Naming**: Use `snake_case` for functions, variables, and files
- **Prefixing**: 
  - Plugin functions: `vim_restman#FunctionName()`
  - Module functions: `vim_restman_module#FunctionName()`
  - Private functions: `s:FunctionName()`
- **Indentation**: 4 spaces
- **Documentation**: All functions must have JSDoc-style comments with @param and @return tags
- **Logging**: Use logging functions from utils module (LogDebug, LogInfo, LogWarning, LogError)
- **Function organization**: Keep functions small (<25 lines), group related functions
- **Error handling**: Check for error conditions and provide meaningful error messages
- **String operations**: Use `trim()` for string trimming
- **File structure**: Follow modular design with `vim_restman_[module].vim` naming

## Testing
- Write tests for all new features in `/test/test_*.vim` files
- Register tests with `RegisterTest(name, function)`
- Test functions should begin with `s:test_`
- Use assertion functions: `s:assert_equal()`, `s:assert_true()`, `s:assert_false()`, `s:assert_match()`