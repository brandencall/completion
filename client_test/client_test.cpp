#include <arpa/inet.h>
#include <cerrno>
#include <iostream>
#include <netdb.h>
#include <netinet/in.h>
#include <stdio.h>
#include <string.h>
#include <string>
#include <sys/socket.h>
#include <sys/types.h>
#include <sys/un.h>
#include <unistd.h>

#define PORT 22222
#define SERVER_IP "127.0.0.1"
#define MAX_BUFFER_SIZE 1024

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

int main() {
    printf("Hello from client\n");

    struct sockaddr_in servAddr;
    servAddr.sin_family = AF_INET;
    servAddr.sin_port = htons(PORT);

    // Convert IPv4 address from text to binary form
    if (inet_pton(AF_INET, SERVER_IP, &servAddr.sin_addr) <= 0) {
        perror("Invalid address/ Address not supported");
    }

    int socketFD = socket(AF_INET, SOCK_STREAM, 0);

    if (socketFD == -1) {
        printf("There was a problem creating the socket file descriptor\n");
    }

    if (connect(socketFD, (struct sockaddr *)&servAddr, sizeof(servAddr)) == -1) {
        printf("Failed to connect...\n");
    }

    send_message(socketFD,
                 R"(int sum_positive(int *arr, int len) { 
                    int total = 0;
                    for (int i = 0; i < len; i++) { 
                        if (arr[i] > 0) { 
                            total +=)");
    close(socketFD);
    return 0;
}
