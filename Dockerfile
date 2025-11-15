FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl \
    git \
    make \
    ca-certificates \
    luarocks \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y software-properties-common && \
    add-apt-repository ppa:neovim-ppa/unstable -y && \
    apt-get update && \
    apt-get install -y neovim && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

COPY . .

ENV NVIM_APPNAME=nvim-neotest-bun-test-docker

RUN mkdir -p /tmp/nvim-test/.config /tmp/nvim-test/.local/share /tmp/nvim-test/.local/state /tmp/nvim-test/.cache

CMD ["make", "test"]
