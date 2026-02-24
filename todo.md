# Todo's:
    - BUG: The render got an invalid buffer id somehow. Probably not tracking buffers correctly
    - BUG: For cpp, when an enum (I'm guessing any kind of block like structure) is on a single line, like in sample.cpp
      the ts_helper for getting the current node, gets the wrong node.
    - Feature: The llm may spam sometimes, should add a suspend cooldown if user doesn't accept response
    - May be nice not to prompt if the number of lines is less than some threshold (prompting on an empty method is probably not useful)
