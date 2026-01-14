#pragma once

int wait_for_client(int socketFD);
int socket_init(int port);
void handle_client_request(int socketFD);
