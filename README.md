# Vim RestMan

A simple REST client plugin for Vim.

## Description

Vim RestMan is a lightweight plugin designed to help developers work with REST APIs directly within Vim. It allows you to capture and display text between delimiters, which can be useful for organizing and executing API requests.

## Features

- Capture text between `--` delimiters
- Display captured text in a dedicated log buffer
- Easy-to-use keyboard shortcut (Ctrl+j)

## Installation

### Using vim-plug

If you use [vim-plug](https://github.com/junegunn/vim-plug) for plugin management (recommended), add the following line to your `.vimrc`:

Plug 'sojohnnysaid/vim-restman'

Then run `:PlugInstall` in Vim.

### Manual Installation

If you prefer to install manually:

1. Clone this repository:
   
   git clone https://github.com/sojohnnysaid/vim-restman.git ~/.vim/pack/plugins/start/vim-restman
   
2. Restart Vim or source your `.vimrc`.

## Usage

1. In your Vim buffer, write your API request between two `--` delimiters. For example:

   --
   GET https://api.example.com/users
   Content-Type: application/json
   
   {
     "user_id": 123
   }
   --

2. Place your cursor anywhere between the delimiters.

3. Press Ctrl+j or run the command `:RestManCapture`.

4. The text between the delimiters will be captured and displayed in a log buffer at the bottom of your Vim window.

## Commands

- `:RestManCapture`: Captures and displays the text between delimiters.

## Mappings

- `Ctrl+j`: Shortcut for the `:RestManCapture` command.

## Configuration

Currently, Vim RestMan doesn't require any additional configuration. It works out of the box once installed.

## Requirements

- Vim 8.0 or newer

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

If you encounter any problems or have any suggestions, please open an issue on the [GitHub repository](https://github.com/sojohnnysaid/vim-restman/issues).

## Authors

- John Hargrove ([@sojohnnysaid](https://github.com/sojohnnysaid))

## Acknowledgments

- Thanks to the Vim community for continuous inspiration and support.

