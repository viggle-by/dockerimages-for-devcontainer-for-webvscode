# Set Ubuntu variant (e.g., noble, jammy, etc.)
ARG VARIANT="noble"
FROM buildpack-deps:${VARIANT}-curl

ARG VARIANT

# Conditionally remove the 'ubuntu' user if using noble variant
RUN if [ "$VARIANT" = "noble" ]; then \
        if id "ubuntu" &>/dev/null; then \
            echo "Deleting user 'ubuntu' for $VARIANT"; \
            userdel -f -r ubuntu || echo "Failed to delete ubuntu user for $VARIANT"; \
        else \
            echo "User 'ubuntu' does not exist for $VARIANT"; \
        fi; \
    fi

# Install prerequisites
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    gnupg \
    sudo \
    apt-transport-https \
    && rm -rf /var/lib/apt/lists/*

# Add Microsoft GPG key and repository for VS Code
RUN curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg && \
    sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/ && \
    sudo sh -c 'echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list' && \
    sudo apt install -y apt-transport-https && \
    sudo apt update && sudo apt install -y code && \
    rm -f packages.microsoft.gpg

# Create a non-root user named 'mysticgiggle'
ARG USERNAME=mysticgiggle
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && usermod -aG sudo $USERNAME \
    && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Switch to non-root user
USER $USERNAME
WORKDIR /home/$USERNAME

# Copy current workspace into container
RUN mkdir -p /home/$USERNAME/workspace
COPY --chown=$USERNAME:$USERNAME . /home/$USERNAME/workspace

# Set environment variable for VS Code Tunnel name
ENV TUNNEL_NAME=devcontainer

# Default entrypoint: run VS Code Tunnel
ENTRYPOINT ["code", "tunnel", "--name", "${TUNNEL_NAME}", "--accept-server-license-terms"]
