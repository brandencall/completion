# Todo's:
    - Complete state tracking for the plugin to determine when to prompt the llm.
        - Prompting on treesitter node types. CURRENTLY ONLY FOR LUA
            [] Local declaration:
                - Prev state { cur_node: function_declaration, contains_chile: ERROR }, Current State { variable_declaration }  
                    - Right before declaraing variable name
                - Prev state { cur_node: function_declaration }, Current State { assignment_statement }  
                    - Right before assigning variable
            [X] If, while, for statements:
                - When cur_node = (if_statement, while_statement, for_statement), cur_row > start_cur_node_row && cur_row < end_cur_node_row
                    - If we are inside one of these statements, then prompt
                    - May not want to prompt if scope contains errors (user in the middle of typing)
            [] DON'T PROMPT WHEN IN:
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
