# Todo's:
    - Complete state tracking for the plugin to determine when to prompt the llm.
        - Current prompting triggers (VERY BASIC PROMPTING TRIGGER):
            - If current node is if_statement, for_statement and while_statement
                - There is no error node present
                - The current row is between the start of the statement and the end of the statement blocks
            - If the current node is an assignment_statement or a binary_expression
            - If the current node is a function and there is no error node present
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
        - C# integration
    - Determine when the suffix is being repeated and stop processing the prompt.
    - Does the llm return a confidence score per token?
    - Start working on a test suite to measure llm.
    - Context building:
        - Currently `get_current_function_pos` only gets the inner most function (in case of nested functions). May want
          to get the outter most function in the future. Lua in many cases has many nested functions (callbacks)
    - BUG: The render got an invalid buffer id somehow. Probably not tracking buffers correctly
    [X] BUG: Sometimes renders after exiting insert mode (Guess is the request is already in flight by the time we switch back)
    - Setup a way to do configuration in nvim configuration
        - LLM model 
        [X] LLM parameters
        - Configure suspend time (?)
    - On startup, figure out a way to start up the LLM server
        - Need to checks on whether llama.cpp is installed, etc.

    -BUG: clear prompt after accepting an LSP suggestion
