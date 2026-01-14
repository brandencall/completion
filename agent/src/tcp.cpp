#include "tcp.h"
#include <httplib.h>
#include <nlohmann/json.hpp>
#include <stdlib.h>

#define CHUNK_SIZE 4096
#define LISTEN_BACKLOG 128
#define MAX_MSG_LENGTH 16384

int socket_init(int port) {
    int socketFD = socket(AF_INET6, SOCK_STREAM, 0);
    if (socketFD == -1) {
        printf("There was a problem creating the socket file descriptor\n");
    }
    struct sockaddr_in6 address;
    memset(&address, 0, sizeof(address));

    address.sin6_family = AF_INET6;
    address.sin6_port = htons(port);
    address.sin6_flowinfo = 0;
    address.sin6_addr = in6addr_any;
    address.sin6_scope_id = 0;

    int opt = 1;
    if (setsockopt(socketFD, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt)) < 0)
        printf("setsockopt FAILED\n");

    if (bind(socketFD, (struct sockaddr *)&address, sizeof(address)) == -1) {
        printf("Bind FAILED!\n");
    }

    if (listen(socketFD, LISTEN_BACKLOG) == -1) {
        printf("Listen FAILED!\n");
    }
    printf("Listening on port %d\n", port);

    return socketFD;
}

int wait_for_client(int socketFD) {
    struct sockaddr_un clientAddr;
    socklen_t clientAddrSize = sizeof(clientAddr);
    int clientFD = accept(socketFD, (struct sockaddr *)&clientAddr, &clientAddrSize);
    printf("client accepted\n");
    return clientFD;
}

bool recv_exact(int sock, void *buffer, size_t length) {
    size_t received = 0;
    char *buf = static_cast<char *>(buffer);

    while (received < length) {
        ssize_t n = recv(sock, buf + received, length - received, 0);

        if (n == 0)
            return false; // peer closed
        if (n < 0) {
            if (errno == EINTR)
                continue;
            perror("recv");
            return false;
        }

        received += n;
    }

    return true;
}

void test_client(int clientSocket) {
    while (true) {
        // Read message length
        uint32_t len_network = 0;
        if (!recv_exact(clientSocket, &len_network, sizeof(len_network))) {
            std::cout << "Client disconnected\n";
            break;
        }
        uint32_t messageLength = ntohl(len_network);

        if (messageLength == 0 || messageLength > MAX_MSG_LENGTH) {
            std::cerr << "Invalid message length: " << messageLength << "\n";
            break;
        }

        std::string message(messageLength, '\0');

        // Read payload
        if (!recv_exact(clientSocket, message.data(), messageLength)) {
            std::cerr << "Failed to receive message payload\n";
            break;
        }

        std::cout << "Client sent (" << messageLength << " bytes)\n";
        std::cout << "Client sent: " << message << "\n";
    }
}

void handle_client_request(int socketFD) {
    while (true) {
        int clientFD = wait_for_client(socketFD);
        // get_client_msg(clientFD);
        test_client(clientFD);
        close(clientFD);
        printf("closed client connection\n");
    }
    close(socketFD);
}
