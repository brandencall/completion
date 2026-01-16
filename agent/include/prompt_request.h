#pragma once

#include <nlohmann/json.hpp>
#include <string>

using json = nlohmann::json;

struct PromptRequest {
    std::string type;
    std::string prefix;
    std::string suffix;
    std::string file_name;
};

void from_json(const json &j, PromptRequest &PromptRequest);
