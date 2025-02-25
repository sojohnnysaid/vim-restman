# Vim RestMan

A robust REST client plugin for Vim with a buffer-per-request approach.

## Description

Vim RestMan is a powerful plugin designed to help developers work with REST APIs directly within Vim. It creates a dedicated buffer for each request, making it easy to compare responses, track history, and maintain context during API testing.

## Features

- Execute REST API requests directly within Vim
- Buffer-per-request approach keeps history of all requests
- Variable capture and substitution for complex API workflows
- JSON response formatting and syntax highlighting
- Multiple variable reference formats (`:var`, `{{var}}`, `$var`)
- Easy navigation between request results
- Support for all main HTTP methods (GET, POST, PUT, DELETE, PATCH)

## Installation

### Using vim-plug

If you use [vim-plug](https://github.com/junegunn/vim-plug) for plugin management (recommended), add the following line to your `.vimrc`:

```vim
Plug 'sojohnnysaid/vim-restman'
```

Then run `:PlugInstall` in Vim.

### Manual Installation

If you prefer to install manually:

1. Clone this repository:
   
   ```bash
   git clone https://github.com/sojohnnysaid/vim-restman.git ~/.vim/pack/plugins/start/vim-restman
   ```
   
2. Restart Vim or source your `.vimrc`.

## Usage

### Creating Request Files

Create a `.rest` file with your API requests using this format:

```
#Globals Start
@variables
base_url=https://api.example.com
token=my-api-token

@capture
response.id
response.user.name
#Globals End

#Requests Start
--
GET {{base_url}}/users
Authorization: Bearer {{token}}
--
POST {{base_url}}/users
Content-Type: application/json
Authorization: Bearer {{token}}

{
  "name": "John Doe",
  "email": "john@example.com"
}
--
GET {{base_url}}/users/{{response.id}}
Authorization: Bearer {{token}}
--
#Requests End
```

### Executing Requests

1. Place your cursor anywhere inside a request block (between the `--` markers)
2. Press `Ctrl+i` or run the command `:RestManExec`
3. A new buffer will open with the request result

### Managing Results

- `:RestManList` - List all request result buffers
- `:RestManGoto N` - Navigate to result buffer N
- `:RestManCloseAll` - Close all result buffers

### Other Commands

- `:RestManDebugOn` - Enable debug mode
- `:RestManDebugOff` - Disable debug mode
- `:RestManReload` - Reload the plugin (useful during development)

### Variable Capture and Substitution

RestMan supports capturing values from responses using the `@capture` section:

```
@capture
response.id
response.token
```

You can then reference these captured values in subsequent requests:

```
GET https://api.example.com/users/{{response.id}}
Authorization: Bearer {{response.token}}
```

## Configuration

Add these settings to your `.vimrc` to customize RestMan:

```vim
" Enable debug mode
let g:vim_restman_debug = 1

" Split direction for result buffers ('vertical' or 'horizontal')
let g:vim_restman_split_direction = 'vertical'

" Split size (width or height depending on direction)
let g:vim_restman_split_size = 80

" Maximum requests to keep in history
let g:vim_restman_max_history = 20
```

## Requirements

- Vim 8.0 or newer
- curl (for making HTTP requests)
- jq (optional, for better JSON formatting)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

If you encounter any problems or have suggestions, please open an issue on the [GitHub repository](https://github.com/sojohnnysaid/vim-restman/issues).

## Authors

- John Hargrove ([@sojohnnysaid](https://github.com/sojohnnysaid))