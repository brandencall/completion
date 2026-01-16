#include "prompt_request.h"
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

std::string llm_post_test(int clientId, std::string msg) {
    std::string prompt = R"(You are a code completion engine. Only output code. Do not explain. Language: C++.
             <BEGIN_CODE>)" +
                         msg;
    json test = {
        {"prompt", prompt}, {"max_tokens", 64}, {"temperature", 0.15}, {"stop", {"<END_CODE>"}}, {"stream", true}};

    std::string payload = test.dump();
    httplib::Client client("http://127.0.0.1:8080");

    httplib::Headers headers = {{"Content-Type", "application/json"}};

    std::string buffer;

    // Testing streaming the post request
    auto data_reciever = [&](const char *data, size_t data_length) {
        std::string chunk(data, data_length);

        // std::cout << chunk << '\n';
        // buffer.append(chunk);
        //  Split lines by '\n'
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
                    //std::cout << token_text; // append this to your buffer
                    buffer.append(token_text);
                    send_message(clientId, token_text);
                }
            }
        }
        return true;
    };

    auto res = client.Post("/v1/completions", headers, payload, "application/json", data_reciever);
    return buffer;
}

void message_handler_test(int clientId, std::string msg) {
    // std::cout << "Client sent: " << msg << "\n";
    // std::cout << "[END OF MSG]" << "\n";
    // send_message(clientId, "Server recieved: " + msg);
    json j = json::parse(msg);
    PromptRequest request = j.get<PromptRequest>();
    std::string response = llm_post_test(clientId, request.prefix);
    std::cout << "FULL RESPONSE: " << '\n';
    std::cout << response << '\n';
}

int main() {
    std::cout << "Hello World" << '\n';
    // llm_post_test();
    int socketFD = socket_init(22222);
    start_tcp(socketFD, message_handler_test);
    return 0;
}
