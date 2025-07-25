.SUFFIXES:

all: documentation lint luals test

clean:
	rm -rf ./tmp

# runs all the test files.
test:
	nvim --version | head -n 1 && echo ''
	mkdir -p ./tmp
	NVIM_APPNAME=nvim-neotest-bun-test \
	XDG_CONFIG_HOME=$$(pwd)/tmp/.config \
	XDG_DATA_HOME=$$(pwd)/tmp/.local/share \
	XDG_STATE_HOME=$$(pwd)/tmp/.local/state \
	XDG_CACHE_HOME=$$(pwd)/tmp/.cache \
	nvim --headless -u ./scripts/minimal_init.lua \
		-c "lua require('mini.test').setup()" \
		-c "lua MiniTest.run({ execute = { reporter = MiniTest.gen_reporter.stdout({ group_depth = 2 }) } })"

test-ci: test

# runs tests in Docker container
test-docker:
	docker build -t neotest-bun-test . && docker run --rm -v $$(pwd):/workspace neotest-bun-test

# generates the documentation.
documentation:
	NVIM_APPNAME=neotest-bun nvim \
		--headless \
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
	curl -sL "https://github.com/LuaLS/lua-language-server/releases/download/3.7.4/lua-language-server-3.7.4-darwin-x64.tar.gz" | tar xzf - -C "${PWD}/.ci/lua-ls"
	make luals-ci
