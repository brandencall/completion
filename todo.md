# Todo's:
    - BUG: The render got an invalid buffer id somehow. Probably not tracking buffers correctly
    - BUG: For cpp, when an enum (I'm guessing any kind of block like structure) is on a single line, like in sample.cpp
      the ts_helper for getting the current node, gets the wrong node.
    - Make suspend timer part of the configuration
    - BUG: 
```
Error detected while processing CursorMovedI Autocommands for "<buffer=38>":
Error executing lua callback: /usr/share/nvim/runtime/lua/vim/snippet.lua:347: attempt to index field '_session' (a nil value)
stack traceback:
        /usr/share/nvim/runtime/lua/vim/snippet.lua:347: in function </usr/share/nvim/runtime/lua/vim/snippet.lua:338>
```
