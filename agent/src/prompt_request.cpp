#include "prompt_request.h"
#include "tcp.h"
#include <httplib.h>
#include <optional>
#include <string>

void from_json(const json &j, PromptRequest &PromptRequest) {
    j.at("type").get_to(PromptRequest.type);
    j.at("prefix").get_to(PromptRequest.prefix);
    j.at("suffix").get_to(PromptRequest.suffix);
    j.at("file_name").get_to(PromptRequest.file_name);
}

void llm_request(int clientId, PromptRequest &request) {
    std::string prefix = "<file>" + request.file_name + "</file>\n" + request.prefix;
    std::cout << "Prefix:\n" << prefix << "\n";
    std::cout << "Suffix:\n" << request.suffix << "\n";
    json jsonRequest = {{"max_tokens", 128},
                        {"input_prefix", prefix},
                        {"input_suffix", request.suffix},
                        {"temperature", 0.7},
                        {"stop", {"\n\n", "\n\n\n", "<fim_prefix>", "<fim_suffix>", "<fim_middle>", "```", "</"}},
                        {"top-p", 0.9},
                        {"top-k", 40},
                        {"repeat-penalty", 1.1},
                        {"presence-penalty", 0.0},
                        {"frequency-penalty", 0.0},
                        {"stream", true}};

    std::string payload = jsonRequest.dump();
    httplib::Client client("http://127.0.0.1:8080");

    httplib::Headers headers = {{"Content-Type", "application/json"}};

    std::cout << "LLM Response:\n";
    auto data_reciever = [&](const char *data, size_t data_length) {
        std::string chunk(data, data_length);
        //  Split lines by '\n'
        size_t pos = 0;
        while ((pos = chunk.find("\n")) != std::string::npos) {
            std::string line = chunk.substr(0, pos);
            chunk.erase(0, pos + 1);
            if (line.find("data: ") == 0) { // starts with "data: "
                std::string jsonStr = line.substr(6);
                json j = json::parse(jsonStr);
                if (j.contains("content") && j.contains("stop")) {
                    if (j["stop"] == true)
                        break;
                    std::string token_text = j["content"];
                    std::cout << token_text;
                    send_message(clientId, token_text);
                }
            }
        }
        return true;
    };

    auto res = client.Post("/infill", headers, payload, "application/json", data_reciever);
    std::cout << "\n";
}

void prompt_handler(int clientId, const std::string &request) {
    if (request == std::string::npos)
        return;
    json j = json::parse(request);
    PromptRequest promptRequest = j.get<PromptRequest>();
    llm_request(clientId, promptRequest);
}
