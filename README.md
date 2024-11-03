# 🚀 vim-restman

![image](https://github.com/user-attachments/assets/83ebccd8-cc4c-4db2-a7e6-22605995ae3d)


Make API requests from the comfort of your Vim editor! 🛋️

## 🎭 What is vim-restman?

vim-restman is a Vim plugin that lets you send API requests directly from your Vim environment, just like Postman, but cooler! 😎 Save auth tokens on the fly and embrace the power of Vim for all your API testing needs.

## 🌟 Features

- Make API requests right from your Vim editor 📡
- Save authentication tokens automatically 🔐
- Use .rest files to organize your API calls 📁
- Global variables and headers support 🌍
- Capture and reuse response data 🎣

## 🛠️ Installation
Using vim-plug:

vim Plug 'sojohnnysaid/vim-restman'

🚦 How to Use
1. Create a .rest file (all files must have the .rest extension).
2. Set up your globals, variables, and requests.
3. Move your cursor between the -- delimiters.
4. Press Ctrl+i to send the API request.
5. Watch the magic happen on the right side of your screen! ✨

## 📝 Example .rest File

```text

Globals Start
@base_url http://localhost:8090

@headers Content-Type: application/json Authorization: Bearer

@variables username=$username password=$password

@capture token

Globals End
Requests Start
-- POST /api/collections/users/auth-with-password { "identity":"
", "password":"
" }
-- GET /api/collections/applicants/records
Requests End
```

## 🎉 Why vim-restman?
- Because Vim is life 💚
- API testing should be fun 🎈
- Impress your colleagues with your Vim wizardry 🧙‍♂️
## 🤝 Contributing
Pull requests are welcome! For major changes, please open an issue first to discuss what you would like to change.

## 📜 License
MIT

## 🙋‍♂️ Author
Created with love by [Your Name] 💖

Remember, with great power comes great responsibility. Use vim-restman wisely! 🦸‍♂️
