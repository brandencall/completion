# Todo's:
    - Complete state tracking for the plugin to determine when to prompt the llm.
        - Prompting on treesitter node types.
            - Do's:
                - assignment_statement
                - parameter_list
                - return_statement (?)
                - if_statement (?)
                - while_statement (?)
                - for_statement (?)
                - compound_statement (?) (`{`, `}`)
            - Dont's:
                - string_literal
                - comment
    - Determine when the suffix is being repeated and remove it.
    - Start working on a test suite to measure llm.
    - LLM will respond with the suffix code as well sometimes. Need a way to detect that and not display.
        - This needs to be done on the plugin side because we are streamming the content (I don't think that the cpp
          agent code will be able to detect this).
    - Context building:
        - Currently `get_current_function_pos` only gets the inner most function (in case of nested functions). May want
          to get the outter most function in the future. Lua in many cases has many nested functions (callbacks)
