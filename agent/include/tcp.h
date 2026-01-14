#pragma once

#include <cstddef>
#include <cstdint>
#include <optional>
#include <string>

int socket_init(int port);
void start_tcp(int socketFD);
int wait_for_client(int socketFD);
void handle_client_connection(int clientSocket);
uint32_t message_length(int clientSocket, bool &runFlag);
bool valid_message_length(uint32_t messageLength);
bool recv_exact(int sock, void *buffer, size_t length);
std::optional<std::string> client_payload(int clientSocket, uint32_t messageLength, bool &runFlag);
