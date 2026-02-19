# Todo's:
    - Does the llm return a confidence score per token?
    - BUG: The render got an invalid buffer id somehow. Probably not tracking buffers correctly
    - On startup, figure out a way to start up the LLM server
        - Need to checks on whether llama.cpp is installed, etc.
    - Need to add character triggers instead of relying on treesitters node to trigger
        - For example, would like to trigger on `member_access_expression` but that will always be an error when the user
          is typing. Need to "hard code" these triggers for each individual language. Then the lang context builder can
          check if the current line contains those triggers
