local iLang = require("completion.lang.lang")

local M = {}

M.langs = {
    lua = require("completion.lang.lua"),
    csharp = require("completion.lang.csharp"),
    cpp = require("completion.lang.cpp")
}

for name, lang in pairs(M.langs) do
    iLang.validate(lang, name)
end

function M.get_active_lang(bufnr)
    for _, lang in pairs(M.langs) do
        if lang.is_applicable(bufnr) then
            return lang
        end
    end
end

return M
