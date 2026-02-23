# Todo's:
    - BUG: The render got an invalid buffer id somehow. Probably not tracking buffers correctly
    - BUG: For cpp, when an enum (I'm guessing any kind of block like structure) is on a single line, like in sample.cpp
      the ts_helper for getting the current node, gets the wrong node.
    - On startup, figure out a way to start up the LLM server
        - BUG: If the use opens an nvim instance as the llm server is starting, it will not get a response from /health
               so it will start another instance of the llm server. Most of the time this shouldn't be a problem unless
               the user is frequently openning new nvim instances. (Checking the "llama-server" process may stop this
               from happening but it isn't as clean as calling the /health endpoint)
        [X] Automatic starup and shutdown.
        - Need to checks on whether llama.cpp is installed if a startup path is included.
        [X] Need to check if a instance of the llm server is already started before starting another.
            [X] Figure out a way to shutdown the llm server only when no other nvim instances are running.
    - Feature: The llm may spam sometimes, should add a suspend cooldown if user doesn't accept response
    - May be nice not to prompt if the number of lines is less than some threshold (prompting on an empty method is probably not useful)
