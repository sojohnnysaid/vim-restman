# Vim RestMan Developer Guide

## 1. Executive Summary

### Project Purpose
Vim RestMan is a REST API client plugin for Vim that allows developers to make HTTP requests directly from within their Vim editor. It provides functionality similar to Postman but integrated into the Vim environment.

### Main Technologies
- VimScript (Vim's native scripting language)
- curl (for HTTP requests)
- jq (optional, for JSON formatting)

### Key Features
- Make HTTP requests directly from Vim
- Parse .rest files containing API request definitions
- Variable capture and substitution
- Response display with syntax highlighting
- Split window interface
- JSON response formatting
- Request history tracking

## 2. Project Architecture

### High-Level Overview
The plugin follows a modular architecture with clear separation of concerns:

```
vim-restman
├── plugin/
│   └── vim-restman.vim         # Plugin initialization
└── autoload/
    ├── vim_restman.vim         # Core orchestrator
    ├── vim_restman_utils.vim   # Utility functions
    ├── vim_restman_file_parser.vim    # Request file parsing
    ├── vim_restman_curl_builder.vim   # Request building
    ├── vim_restman_buffer_manager.vim # Display management
    ├── vim_restman_window_manager.vim # Window management
    └── vim_restman_capture_manager.vim # Variable capture
```

### Key Components
1. **Core Orchestrator** (`vim_restman.vim`)
   - Coordinates between components
   - Manages plugin lifecycle
   - Handles main workflow

2. **File Parser** (`vim_restman_file_parser.vim`)
   - Parses .rest files
   - Extracts request definitions
   - Processes global configurations

3. **Curl Builder** (`vim_restman_curl_builder.vim`)
   - Constructs curl commands
   - Handles request formatting
   - Manages variable substitution

4. **Display Management** (`vim_restman_buffer_manager.vim`)
   - Manages output display
   - Handles syntax highlighting
   - Formats responses

### Data Flow
1. User opens/edits .rest file
2. File parser processes request definitions
3. Curl builder creates HTTP request
4. Request is executed
5. Response is captured and processed
6. Results displayed in split window
7. Variables captured for future use

## 3. Setup & Installation

### Prerequisites
- Vim 8.0 or newer
- curl installed on system
- jq (optional) for JSON formatting

### Installation

#### Using vim-plug
```viml
Plug 'sojohnnysaid/vim-restman'
```

#### Manual Installation
```bash
git clone https://github.com/sojohnnysaid/vim-restman.git
cp -r vim-restman/plugin/* ~/.vim/plugin/
cp -r vim-restman/autoload/* ~/.vim/autoload/
```

### Configuration
Add to your .vimrc:
```viml
" Optional: Custom key mapping
nmap <your-preferred-key> <Plug>RestManMain

" Optional: Window settings
let g:restman_window_size = 40
```

## 4. Code Organization

### Directory Structure
```
vim-restman/
├── plugin/          # Plugin initialization
├── autoload/        # Core functionality
├── doc/            # Documentation
├── LICENSE         # MIT License
└── README.md       # User documentation
```

### Key Files
- `plugin/vim-restman.vim`: Plugin entry point
- `autoload/vim_restman.vim`: Core orchestration
- `autoload/vim_restman_file_parser.vim`: Request parsing
- `autoload/vim_restman_curl_builder.vim`: Request building

## 5. Core Concepts

### Request File Format
```
#Globals Start
@variables
base_url=https://api.example.com
token=12345

@capture
response.id=captured_id

#Requests Start
GET /users
Authorization: Bearer {{token}}
--
POST /users
Content-Type: application/json

{"name": "John"}
--
#Requests End
```

### Data Structures

#### Request Object
```viml
{
    'method': 'GET|POST|PUT|DELETE',
    'endpoint': '/path',
    'headers': ['Header: Value'],
    'body': 'request body'
}
```

#### Variables Dictionary
```viml
{
    'variable_name': {
        'value': 'variable value',
        'set': 1
    }
}
```

## 6. Development Workflow

### Adding New Features
1. Create feature branch
2. Add functionality in appropriate autoload file
3. Update main orchestrator if needed
4. Add documentation
5. Test manually
6. Submit PR

### Testing
```viml
" Run basic functionality test
:RestManMain
" Test variable capture
:echo vim_restman_capture_manager#GetAllCapturedValues()
```

## 7. API Reference

### Core Functions

#### Main Orchestrator
```viml
vim_restman#Main()
" Main entry point for plugin execution

vim_restman#CleanUp()
" Cleanup plugin resources
```

#### File Parser
```viml
vim_restman_file_parser#ParseCurrentFile()
" Parse current .rest file
```

#### Curl Builder
```viml
vim_restman_curl_builder#BuildCurlCommand(parsed_data, request_index, variables)
" Build curl command from request data
```

## 8. Common Tasks

### Creating a New Request
```
#Requests Start
GET /api/users
Authorization: Bearer {{token}}
--
#Requests End
```

### Capturing Variables
```
@capture
response.id=user_id
response.token=auth_token
```

### Using Captured Variables
```
GET /api/users/{{user_id}}
Authorization: Bearer {{auth_token}}
```

### Best Practices
1. Use meaningful variable names
2. Group related requests together
3. Include appropriate headers
4. Document request purpose in comments
5. Use proper indentation in request bodies
6. Clean up captured variables when done

---

**Note**: This plugin requires 'nocompatible' mode in Vim and curl installed on your system.

**Warning**: Be careful with sensitive data in .rest files. Consider using environment variables for tokens and credentials.