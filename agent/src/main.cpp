#include "prompt_request.h"
#include "tcp.h"
#include <httplib.h>
#include <iostream>
#include <nlohmann/json.hpp>
#include <stdlib.h>

#define LISTEN_BACKLOG 128
#define PORT 22222
using nlohmann::json;

using json = nlohmann::json;

int main() {
    std::cout << "Hello World" << '\n';
    int socketFD = socket_init(22222);
    start_tcp(socketFD, prompt_handler);
    return 0;
}
