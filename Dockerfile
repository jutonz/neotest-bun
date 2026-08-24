FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# `gcc`/`libc6-dev` rather than `build-essential`: the typescript and javascript
# grammars ship only a C scanner, so no C++ compiler is needed. luarocks is not
# installed because the harness disables rocks (see scripts/minimal_init.lua).
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    make \
    unzip \
    ca-certificates \
    gcc \
    libc6-dev \
    && rm -rf /var/lib/apt/lists/*

# Install neovim
RUN apt-get update && apt-get install -y software-properties-common && \
    add-apt-repository ppa:neovim-ppa/unstable -y && \
    apt-get update && \
    apt-get install -y neovim && \
    rm -rf /var/lib/apt/lists/*

# nvim-treesitter's `main` branch compiles parsers with tree-sitter-cli.
# Installed before bun so that bumping BUN_VERSION does not re-download it.
ARG TREE_SITTER_VERSION=0.26.13
ARG TARGETARCH
RUN case "${TARGETARCH}" in \
      arm64) TS_ARCH=linux-arm64 ;; \
      amd64) TS_ARCH=linux-x64 ;; \
      *) echo "unsupported arch: ${TARGETARCH}" >&2; exit 1 ;; \
    esac \
    && curl -fsSL --retry 3 --retry-delay 2 \
    "https://github.com/tree-sitter/tree-sitter/releases/download/v${TREE_SITTER_VERSION}/tree-sitter-${TS_ARCH}.gz" \
    -o /tmp/tree-sitter.gz \
    && gunzip /tmp/tree-sitter.gz \
    && chmod +x /tmp/tree-sitter \
    && mv /tmp/tree-sitter /usr/local/bin/tree-sitter

# Install bun. Override with `--build-arg BUN_VERSION=x.y.z` to test another
# release. Kept last: it is the argument that changes most often.
ARG BUN_VERSION=1.4.0
RUN case "${TARGETARCH}" in \
      arm64) BUN_ARCH=aarch64 ;; \
      amd64) BUN_ARCH=x64 ;; \
      *) echo "unsupported arch: ${TARGETARCH}" >&2; exit 1 ;; \
    esac \
    && curl -fsSL --retry 3 --retry-delay 2 \
    "https://github.com/oven-sh/bun/releases/download/bun-v${BUN_VERSION}/bun-linux-${BUN_ARCH}.zip" \
    -o /tmp/bun.zip \
    && unzip /tmp/bun.zip -d /tmp/bun_unzipped \
    && mv "/tmp/bun_unzipped/bun-linux-${BUN_ARCH}" /opt/bun \
    && rm -r /tmp/bun.zip /tmp/bun_unzipped
ENV PATH="/opt/bun:${PATH}"

WORKDIR /workspace

# `make test-docker` bind-mounts the working tree over this, so the copy only
# matters when running the image standalone.
COPY . .

# Deliberately distinct from the Makefile's default appname: host and container
# share ./tmp through the bind mount, and this keeps macOS and Linux parser .so
# files in separate trees.
ENV NVIM_APPNAME=nvim-neotest-bun-test-docker

CMD ["make", "test"]
