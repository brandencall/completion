# completion
Local AI-powered contextual autocomplete for Neovim

completion is a lightwieght AI-assited autocomplete plugin for Neovim. It provides context-aware code suggestions based
on the current buffer and current cursor position. completion is designed to send requests to a locally hosted llama.cpp 
LLM endpoint. If the llama.cpp server is being hosted on the same machine, then completion will startup and shutdown
the server automatically when Neovim starts up and shuts down.

completion is designed to:
- Work locally with locally hosted LLM's.
- Prompt automatically as the user types.

## Demo
<video src="assets/completion_demo.mp4" controls width="800"></video>

## Features
- Automatic LLM server startup and shutdown.
- Tree-sitter context awareness.
- Per language prompting triggers.
- Automatic LLM prompting

Current supported languages:
- lua
- csharp

## Installation
Using lazy.nvim:
```lua
return {
    {
        "brandencall/completion",
        config = function()
            require("completion").setup()
        end
    }
}
```

## Configuration

```lua
require("completion").setup({
    model = "Qwen/Qwen2.5-Coder-7B-Instruct-GGUF:Q4_K_M",
    server = {
        startup_path = "/home/brabs/Applications/llama.cpp/build/bin/llama-server",
        host = "http://127.0.0.1",
        port = "8080",
        endpoint = "/infill",
    },
    max_tokens = 64,
    temperature = 0.2,
    stop = { "\n\n", "\n\n\n", "```" },
    top_p = 0.9,
    top_k = 40,
    repeat_penalty = 1.1,
    presence_penalty = 0.0,
    frequency_penalty = 0.0,
})
```
The startup path is used only if the server is on the same machine (this enables automatic startup)

## Usage
The plugin automatically triggers in Insert mode after idle timeout and if certian trigger criteria is met.

Accept suggestion:
`<Tab>`

Dismiss suggestion:
`<Esc>` (or keep typing)

Commands:
- CompletionEnable will enable the plugin (and starts up the server if hosted on the same machine).
- CompletionDisable will disable the plugin (and shuts down the server if hosted on the same machine).
