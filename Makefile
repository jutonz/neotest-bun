.SUFFIXES:
.PHONY: all clean test test-ci test-docker documentation documentation-ci lint luals luals-ci

all: documentation lint luals test

clean:
	rm -rf ./tmp

NVIM_APPNAME ?= nvim-neotest-bun-test

test:
	nvim --version | head -n 1 && echo ''
	mkdir -p ./tmp
	rm -f ./tmp/.local/state/${NVIM_APPNAME}/neotest.log
	NVIM_APPNAME=$(NVIM_APPNAME) \
	XDG_CONFIG_HOME=$$(pwd)/tmp/.config \
	XDG_DATA_HOME=$$(pwd)/tmp/.local/share \
	XDG_STATE_HOME=$$(pwd)/tmp/.local/state \
	XDG_CACHE_HOME=$$(pwd)/tmp/.cache \
	nvim --headless -u ./scripts/minimal_init.lua \
		-c "lua require('mini.test').setup()" \
		-c "lua MiniTest.run({ execute = { reporter = MiniTest.gen_reporter.stdout({ group_depth = 2 }) } })"

test-ci: test

# runs tests in Docker container.
# Override the bun release under test with `make test-docker BUN_VERSION=1.3.2`.
BUN_VERSION ?= 1.4.0
TREE_SITTER_VERSION ?= 0.26.13
DOCKER_TAG = neotest-bun-test:bun-$(BUN_VERSION)-ts-$(TREE_SITTER_VERSION)

test-docker:
	docker build \
		--build-arg BUN_VERSION=$(BUN_VERSION) \
		--build-arg TREE_SITTER_VERSION=$(TREE_SITTER_VERSION) \
		-t $(DOCKER_TAG) . \
		&& docker run --rm -v $$(pwd):/workspace $(DOCKER_TAG)

# generates the documentation.
documentation:
	mkdir -p ./tmp
	NEOTEST_BUN_SKIP_PARSERS=1 \
	NVIM_APPNAME=nvim-neotest-bun-test \
	XDG_CONFIG_HOME=$$(pwd)/tmp/.config \
	XDG_DATA_HOME=$$(pwd)/tmp/.local/share \
	XDG_STATE_HOME=$$(pwd)/tmp/.local/state \
	XDG_CACHE_HOME=$$(pwd)/tmp/.cache \
	nvim --headless \
		-u ./scripts/minimal_init.lua \
		-c "lua require('mini.doc').generate()" \
		-c "qa!"

documentation-ci: documentation

# performs a lint check and fixes issue if possible, following the config in `stylua.toml`.
lint:
	stylua . -g '*.lua' -g '!nightly/'
	luacheck plugin/ lua/

luals-ci:
	rm -rf .ci/lua-ls/log
	lua-language-server --configpath .luarc.json --logpath .ci/lua-ls/log --check .
	[ -f .ci/lua-ls/log/check.json ] && { cat .ci/lua-ls/log/check.json 2>/dev/null; exit 1; } || true

luals:
	mkdir -p .ci/lua-ls
	curl -fsSL "https://github.com/LuaLS/lua-language-server/releases/download/3.7.4/lua-language-server-3.7.4-darwin-x64.tar.gz" | tar xzf - -C "${PWD}/.ci/lua-ls"
	make luals-ci
