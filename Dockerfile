# Set Ubuntu variant (e.g., noble, jammy, etc.)
ARG VARIANT="noble"
FROM buildpack-deps:${VARIANT}-curl

# Repeat the ARG after FROM to reuse it later
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

# Install dependencies needed for VS Code CLI (tunnel)
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Download and install VS Code CLI (for VS Code Tunnel)
RUN curl -fsSL https://code.visualstudio.com/sha/download?build=stable&os=cli-alpine-x64 \
    -o vscode_cli.tar.gz && \
    mkdir -p /usr/local/vscode-cli && \
    tar -xzf vscode_cli.tar.gz -C /usr/local/vscode-cli --strip-components=1 && \
    rm vscode_cli.tar.gz && \
    ln -s /usr/local/vscode-cli/bin/code /usr/local/bin/code

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
ENV TUNNEL_NAME=Codespaces: super balls

# Default entrypoint: run VS Code Tunnel
ENTRYPOINT ["code", "tunnel", "--name", "${TUNNEL_NAME}", "--accept-server-license-terms"]
