# Todo's:
    - Does the llm return a confidence score per token?
    - BUG: The render got an invalid buffer id somehow. Probably not tracking buffers correctly
    - On startup, figure out a way to start up the LLM server
        - Need to checks on whether llama.cpp is installed, etc.
    - Need to add character triggers instead of relying on treesitters node to trigger
        - For example, would like to trigger on `member_access_expression` but that will always be an error when the user
          is typing. Need to "hard code" these triggers for each individual language. Then the lang context builder can
          check if the current line contains those triggers

    -BUG: clear prompt after accepting an LSP suggestion
    -BUG:
        ```
        Error detected while processing User Autocommands for "AgentResponse":
        Error executing lua callback: ...ects/completion/lua/completion/agent_response/render.lua:33: attempt to index a nil value
        stack traceback:
                ...ects/completion/lua/completion/agent_response/render.lua:33: in function 'create_extmarks_for_render'
                ...ects/completion/lua/completion/agent_response/render.lua:116: in function 'show_agent_response'
                ...ects/completion/lua/completion/agent_response/render.lua:125: in function <...ects/completion/lua/completion/agent_response/render.lua:122>
                [C]: in function 'nvim_exec_autocmds'
                /home/brabs/projects/completion/lua/completion/http.lua:100: in function </home/brabs/projects/completion/lua/completion/http.lua:99>
        ```
