CONTAINER_CLI ?= docker

build: clean oidc.wasm

oidc.wasm:
	@echo \#\#\# Building wasm module...
	@cargo build --target wasm32-unknown-unknown --release
	@cp target/wasm32-unknown-unknown/release/oidc_filter.wasm ./oidc.wasm

image: oidc.wasm
	@echo \#\#\# Building container...
	@${CONTAINER_CLI} build -f container/Dockerfile . -t oidc-filter

.PHONY: clean
clean:
	@echo \#\#\# Cleaning up...
	@rm oidc.wasm || true
