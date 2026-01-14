#include "tcp.h"
#include <httplib.h>
#include <iostream>
#include <nlohmann/json.hpp>
#include <stdlib.h>
#include <string>

#define LISTEN_BACKLOG 128
#define PORT 22222
using nlohmann::json;

using json = nlohmann::json;

void llm_post_test(std::string msg) {
     std::string prompt = R"(You are a code completion engine. Only output code. Do not explain. Language: C.
             <BEGIN_CODE>)" + msg;
    json test = {
        {"prompt", prompt}, {"max_tokens", 64}, {"temperature", 0.15}, {"stop", {"<END_CODE>"}}, {"stream", true}};

    std::string payload = test.dump();
    httplib::Client client("http://127.0.0.1:8080");

    httplib::Headers headers = {{"Content-Type", "application/json"}};

    // Testing streaming the post request
    auto data_reciever = [&](const char *data, size_t data_length) {
        std::string chunk(data, data_length);

        // std::cout << chunk << '\n';
        // Split lines by '\n'
        size_t pos = 0;
        while ((pos = chunk.find("\n")) != std::string::npos) {
            std::string line = chunk.substr(0, pos);
            chunk.erase(0, pos + 1);

            if (line.find("data: ") == 0 && line.find("data: [DONE]") == std::string::npos) { // starts with "data: "
                std::string jsonStr = line.substr(6);
                // std::cout << line << '\n'; // process token chunk
                json j = json::parse(jsonStr);
                if (j.contains("choices") && j["choices"].is_array() && !j["choices"].empty()) {
                    std::string token_text = j["choices"][0]["text"];
                    std::cout << token_text; // append this to your buffer
                }
            }
        }
        return true;
    };

    auto res = client.Post("/v1/completions", headers, payload, "application/json", data_reciever);

    if (res) {
        std::cout << "Success!" << '\n';
    } else {
        std::cerr << "The request failed" << '\n';
    }
}

void message_handler_test(int clientId, std::string msg) {
    std::cout << "Client sent: " << msg << "\n";
    std::cout << "[END OF MSG]" << "\n";
    llm_post_test(msg);
}

int main() {
    std::cout << "Hello World" << '\n';
    // llm_post_test();
    int socketFD = socket_init(22222);
    start_tcp(socketFD, message_handler_test);
    return 0;
}
