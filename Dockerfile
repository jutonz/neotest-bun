FROM ubuntu:22.04

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    make \
    ca-certificates \
    luarocks \
    && rm -rf /var/lib/apt/lists/*

# Install newer Neovim from unstable PPA (lazy.nvim requires >= 0.8.0)
RUN apt-get update && apt-get install -y software-properties-common && \
    add-apt-repository ppa:neovim-ppa/unstable -y && \
    apt-get update && \
    apt-get install -y neovim && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /workspace

# Copy project files
COPY . .

# Set environment variables for Neovim
ENV NVIM_APPNAME=nvim-neotest-bun-test
ENV XDG_CONFIG_HOME=/tmp/nvim-test/.config
ENV XDG_DATA_HOME=/tmp/nvim-test/.local/share
ENV XDG_STATE_HOME=/tmp/nvim-test/.local/state
ENV XDG_CACHE_HOME=/tmp/nvim-test/.cache

# Create directories for Neovim data
RUN mkdir -p /tmp/nvim-test/.config /tmp/nvim-test/.local/share /tmp/nvim-test/.local/state /tmp/nvim-test/.cache

# Default command
CMD ["make", "test"]
