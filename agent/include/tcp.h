#pragma once

#include <cstddef>
#include <cstdint>
#include <functional>
#include <optional>
#include <string>

using PromptHandler = std::function<void(int client_id, const std::string& message)>;

int socket_init(int port);
void start_tcp(int socketFD, PromptHandler handler);
int wait_for_client(int socketFD);
void handle_client_connection(int clientSocket, PromptHandler handler);
uint32_t message_length(int clientSocket, bool &runFlag);
bool valid_message_length(uint32_t messageLength);
bool recv_exact(int sock, void *buffer, size_t length);
std::optional<std::string> client_payload(int clientSocket, uint32_t messageLength, bool &runFlag);
bool send_message(int sock, const std::string &message);
