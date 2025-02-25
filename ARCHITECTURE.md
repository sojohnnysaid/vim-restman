# Vim-RestMan Architecture

## Design Philosophy
The redesigned vim-restman follows a Buffer-Per-Request approach, where:
- Each request execution creates a new dedicated buffer
- Buffers are organized in a list for easy navigation
- All buffers share common state (variables, environment)
- The design is modular with focused components

## Core Components

### Request Parser
- Parses `.rest` files to extract request definitions
- Processes variables and capture instructions
- Provides a clean interface for the rest of the system

### Request Manager
- Manages execution of requests
- Handles execution context (variables, state)
- Maintains a history of executed requests

### Buffer Manager
- Creates and manages request result buffers
- Handles buffer naming, organization and cleanup
- Provides navigation between request buffers

### Execution Engine
- Handles the execution of HTTP requests (via curl)
- Processes responses and captures specified values
- Handles execution errors gracefully

### Variable Store
- Maintains the global variable context
- Handles variable substitution in requests
- Supports capturing values from responses

### UI Manager
- Manages buffer creation and display
- Handles syntax highlighting and formatting
- Provides UI elements for navigation and control

## Workflow

1. **Parse File**
   - User opens a `.rest` file
   - System parses the file to identify requests and variables

2. **Select Request**
   - User places cursor in a request block
   - User executes the command (Ctrl+i or :RestManMain)

3. **Execute Request**
   - System creates a new buffer for the result
   - System executes the request using curl
   - System processes the response

4. **Display Results**
   - Results are displayed in the new buffer
   - Variables are updated with captured values
   - Syntax highlighting is applied

5. **Navigation**
   - User can navigate between request result buffers
   - User can return to the original request file
   - User can re-execute requests

## Buffer Organization

- **Request Buffers**: Named "RestMan-{timestamp}-{request_method}-{endpoint}"
- **Results Display**: Each buffer contains:
  - Request details (method, URL, headers, body)
  - Response details (status, headers, body)
  - Execution information (time, curl command)
  - Captured variables

## Key Improvements

1. **Isolation**: Each request has its own buffer, preventing interference
2. **History**: Request history is maintained through multiple buffers
3. **Robustness**: No buffer content synchronization issues
4. **Clarity**: Clear separation between requests
5. **Navigation**: Easy navigation between request results