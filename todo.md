# Todo's:
    - Complete state tracking for the plugin to determine when to prompt the llm.
        - Prompting on treesitter node types. CURRENTLY ONLY FOR LUA
            [X] Prompt when type is `%function%` and scope doesn't contain errs
            [X] If, while, for statements:
                - When cur_node = (if_statement, while_statement, for_statement), cur_row > start_cur_node_row && cur_row < end_cur_node_row
                    - If we are inside one of these statements, then prompt
                    - May not want to prompt if scope contains errors (user in the middle of typing)
                - Prompt only on blank lines (?)
                    - Probably not the correct choice.
            - Prompt when encountered (?):
                [X] assignment_statement
                [X] binary_expression
    - Determine when the suffix is being repeated and remove it.
    - Start working on a test suite to measure llm.
    - Context building:
        - Currently `get_current_function_pos` only gets the inner most function (in case of nested functions). May want
          to get the outter most function in the future. Lua in many cases has many nested functions (callbacks)
    - BUG: The render got an invalid buffer id somehow. Probably not tracking buffers correctly
    [X] BUG: Sometimes renders after exiting insert mode (Guess is the request is already in flight by the time we switch back)
    - Setup a way to do configuration in nvim configuration
        - Configure LLM model + it's configuration
        - Configure suspend time (?)
    - On startup, figure out a way to start up the LLM server
        - Need to checks on whether llama.cpp is installed, etc.
