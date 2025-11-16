FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl \
    git \
    make \
    ca-certificates \
    luarocks \
    && rm -rf /var/lib/apt/lists/*

# Install neovim
RUN apt-get update && apt-get install -y software-properties-common && \
    add-apt-repository ppa:neovim-ppa/unstable -y && \
    apt-get update && \
    apt-get install -y neovim && \
    rm -rf /var/lib/apt/lists/*

# Install bun
RUN curl -L \
    https://github.com/oven-sh/bun/releases/download/bun-v1.3.2/bun-linux-aarch64.zip \
    -o /tmp/bun.zip \
    && unzip /tmp/bun.zip -d /tmp/bun_unzipped \
    && mv /tmp/bun_unzipped/bun-linux-aarch64 /opt/bun \
    && rm -r /tmp/bun.zip /tmp/bun_unzipped
ENV PATH="/opt/bun:${PATH}"

WORKDIR /workspace

COPY . .

ENV NVIM_APPNAME=nvim-neotest-bun-test-docker

RUN mkdir -p /tmp/nvim-test/.config /tmp/nvim-test/.local/share /tmp/nvim-test/.local/state /tmp/nvim-test/.cache

CMD ["make", "test"]
