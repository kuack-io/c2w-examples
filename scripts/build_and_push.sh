#!/bin/bash
#
# Script that builds and pushes a Linux and WASM variant of a given image.
#
# Flag legend:
# -e: exit immediately if one of the commands fails
# -u: throw an error if one of the inputs is not set
# -o pipefail: result is the value of the last command
# +x: do not print all executed commands to terminal
set -euo pipefail
set +x

# mandatory
export C2W_CACHE_DIR

REGISTRY_NAMESPACE="ghcr.io/kuack-io/c2w-examples"
IMAGE_NAME=$1

if [ -z "$IMAGE_NAME" ]; then
  echo "Usage: $0 <image-name>"
  exit 1
fi

# assuming IMAGE_NAME is like `alpine:latest`
dest_image_base="${REGISTRY_NAMESPACE}/${IMAGE_NAME}"
image_repo=$(echo "$IMAGE_NAME" | cut -d: -f1)
image_tag=$(echo "$IMAGE_NAME" | cut -d: -f2)
dest_full="${REGISTRY_NAMESPACE}/${image_repo}:${image_tag}"

echo "Processing $IMAGE_NAME -> $dest_full"
docker pull "$IMAGE_NAME"
echo "Pushing Linux variant..."
linux_tag="${dest_full}-linux"
docker tag "$IMAGE_NAME" "$linux_tag"
docker push "$linux_tag"
echo "Converting to WASM..."
rm -f out.wasm

# check for c2w binary in path or specific cache location
if ! command -v c2w &> /dev/null; then
  mkdir -p "$C2W_CACHE_DIR"

  if [ -f "$C2W_CACHE_DIR/c2w" ]; then
    C2W_CMD="$C2W_CACHE_DIR/c2w"
    echo "Using cached c2w at $C2W_CMD"
  else
    echo "c2w not found, downloading v0.8.3 to $C2W_CACHE_DIR..."
    curl -L -o "$C2W_CACHE_DIR/c2w.tar.gz" https://github.com/container2wasm/container2wasm/releases/download/v0.8.3/container2wasm-v0.8.3-linux-amd64.tar.gz
    tar -xzf "$C2W_CACHE_DIR/c2w.tar.gz" -C "$C2W_CACHE_DIR"
    chmod +x "$C2W_CACHE_DIR/c2w"
    C2W_CMD="$C2W_CACHE_DIR/c2w"
  fi
else
  C2W_CMD="c2w"
fi

echo "Running conversion using $C2W_CMD..."
$C2W_CMD "$IMAGE_NAME" out.wasm

echo "Building and Pushing WASM variant..."
wasm_tag="${dest_full}-wasm"
mkdir -p build_wasm
mv out.wasm build_wasm/
cp Dockerfile build_wasm/Dockerfile

docker buildx build --platform wasi/wasm32 \
    --cache-to type=gha,mode=max \
    --cache-from type=gha \
    -t "$wasm_tag" \
    build_wasm/ --push

echo "Creating Manifest List..."
docker buildx imagetools create -t "$dest_full" \
    "$linux_tag" \
    "$wasm_tag"

echo "Successfully published $dest_full"
