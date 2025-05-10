.SUFFIXES:

all: documentation lint luals test

# runs all the test files.
test:
	nvim --version | head -n 1 && echo ''
	NVIM_APPNAME=neotest-bun nvim --headless -u ./scripts/minimal_init.lua \
		-c "lua require('mini.test').setup()" \
		-c "lua MiniTest.run({ execute = { reporter = MiniTest.gen_reporter.stdout({ group_depth = 2 }) } })"

# runs all the test files on the nightly version, `bob` must be installed.
test-nightly:
	bob use nightly
	make test

# runs all the test files on the 0.8.3 version, `bob` must be installed.
test-0.8.3:
	bob use 0.8.3
	make test

test-ci: test

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

# setup
setup:
	./scripts/setup.sh
