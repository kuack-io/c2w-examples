FROM scratch
COPY out.wasm /
ENTRYPOINT ["/out.wasm"]
