#include "prompt_request.h"

void from_json(const json &j, PromptRequest &PromptRequest) {
    j.at("type").get_to(PromptRequest.type);
    j.at("prefix").get_to(PromptRequest.prefix);
    j.at("suffix").get_to(PromptRequest.suffix);
    j.at("file_name").get_to(PromptRequest.file_name);
}
