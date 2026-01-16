#include "tcp.h"
#include <cstdint>
#include <httplib.h>
#include <nlohmann/json.hpp>
#include <optional>
#include <stdlib.h>
#include <sys/socket.h>

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

    if (listen(socketFD, SOMAXCONN) == -1) {
        printf("Listen FAILED!\n");
    }
    printf("Listening on port %d\n", port);

    return socketFD;
}

// Note: This only handles a single client connection at a time.
// Could add multiple client connection handling but since this is for local LLM hosting, that seems like overkill.
// If needed to handle multiple clients than a shared message queue (producer consumer pattern) would work.
void start_tcp(int socketFD, MessageHandler handler) {
    while (true) {
        int clientFD = wait_for_client(socketFD);
        handle_client_connection(clientFD, handler);
        close(clientFD);
        printf("closed client connection\n");
    }
    close(socketFD);
}

int wait_for_client(int socketFD) {
    struct sockaddr_un clientAddr;
    socklen_t clientAddrSize = sizeof(clientAddr);
    int clientFD = accept(socketFD, (struct sockaddr *)&clientAddr, &clientAddrSize);
    printf("client accepted\n");
    return clientFD;
}

void handle_client_connection(int clientSocket, MessageHandler handler) {
    bool running = true;
    while (running) {
        uint32_t messageLength = message_length(clientSocket, running);
        if (!running || !valid_message_length(messageLength))
            break;

        std::optional<std::string> payload = client_payload(clientSocket, messageLength, running);
        if (!payload.has_value())
            break;

        handler(clientSocket, payload.value());
    }
}

uint32_t message_length(int clientSocket, bool &runFlag) {
    uint32_t len_network = 0;
    if (!recv_exact(clientSocket, &len_network, sizeof(len_network))) {
        std::cout << "Client disconnected\n";
        runFlag = false;
    }
    return ntohl(len_network);
}

bool valid_message_length(uint32_t messageLength) {
    if (messageLength == 0 || messageLength > MAX_MSG_LENGTH) {
        std::cerr << "Invalid message length: " << messageLength << "\n";
        return false;
    }
    return true;
}

std::optional<std::string> client_payload(int clientSocket, uint32_t messageLength, bool &runFlag) {
    std::string message(messageLength, '\0');
    std::cout << "messageLength received: " << messageLength << '\n';
    if (!recv_exact(clientSocket, message.data(), messageLength)) {
        std::cerr << "Failed to receive message payload\n";
        runFlag = false;
        return std::nullopt;
    }
    return message;
}

// Using void* so that it is a generic pointer that can point to any data type (uint32_t, string, etc...)
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

bool send_exact(int sock, const void *buffer, size_t length) {
    size_t sent = 0;
    const char *buf = static_cast<const char *>(buffer);

    while (sent < length) {
        ssize_t n = send(sock, buf + sent, length - sent, 0);

        if (n <= 0) {
            if (n < 0 && errno == EINTR)
                continue;
            perror("send");
            return false;
        }

        sent += n;
    }

    return true;
}

bool send_message(int sock, const std::string &message) {
    uint32_t len = message.size();

    // Optional safety check
    constexpr uint32_t MAX_MESSAGE_SIZE = 1024 * 1024;
    if (len > MAX_MESSAGE_SIZE) {
        std::cerr << "Message too large\n";
        return false;
    }

    uint32_t len_network = htonl(len);

    // Send header
    if (!send_exact(sock, &len_network, sizeof(len_network)))
        return false;

    // Send payload
    if (!send_exact(sock, message.data(), len))
        return false;

    return true;
}
