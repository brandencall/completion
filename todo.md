# Todo's:
    - Complete state tracking for the plugin to determine when to prompt the llm.
    - Determine when the suffix is being repeated and remove it.
    - Start working on a test suite to measure llm.
    - LLM will respond with the suffix code as well sometimes. Need a way to detect that and not display.
        - This needs to be done on the plugin side because we are streamming the content (I don't think that the cpp
          agent code will be able to detect this).
