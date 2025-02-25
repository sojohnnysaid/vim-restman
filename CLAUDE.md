# VIM RESTMAN DEVELOPMENT GUIDE

## Commands
- Run tests: `:RestManRunTests`
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
- **Logging**: Use appropriate logging functions:
  - `vim_restman_utils#LogDebug()` for debug messages (only shown when debug mode is on)
  - `vim_restman_utils#LogInfo()` for informational messages
  - `vim_restman_utils#LogWarning()` for warning messages
  - `vim_restman_utils#LogError()` for error messages
- **Function organization**: 
  - Group related functions together
  - Keep functions small and focused (< 25 lines)
  - Break large functions into smaller ones
- **Error handling**: Always check for error conditions and provide meaningful error messages
- **String operations**: Use `trim()` for string trimming

## Architecture
- Modular design with clear separation of concerns
- File naming: `vim_restman_[module].vim`
- Variable substitution supports multiple formats: `:var`, `{{var}}`, `$var`, and JSON dot notation
- Error states are handled gracefully with proper user feedback
- JSON processing supports jq for advanced formatting

## Testing
- Write tests for all new features
- Place tests in `/test/test_*.vim` files
- Run tests with `:RestManRunTests` command
- Use assertion functions: `s:assert_equal()`, `s:assert_true()`, etc.