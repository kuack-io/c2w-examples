# c2w-examples

This project hosts a collection of well-known 3rd-party container images converted into multi-platform OCI images (Linux x86_64 + WASM).

The goal is to provide images that can run both on:
-   **Standard Kubernetes nodes** (using the original Linux binary).
-   **Kuack nodes** (using the converted WASM binary via `container2wasm`).

## How it works

1.  The project maintains a list of images in [images.txt](images.txt).
2.  A [GitHub Actions workflow](.github/workflows/ci.yml) reads this list.
3.  For each image, it:
    -   Pulls the original Linux image.
    -   Converts it to WASM using [container2wasm](https://github.com/ktock/container2wasm).
    -   Builds a new WASM-based container.
    -   Publishes a multi-arch manifest to GitHub Container Registry (GHCR).

## How to add new images

1.  Edit `images.txt`.
2.  Add the image name on a new line (e.g., `redis:7-alpine`).
3.  Commit and push to the `main` branch.

The pipeline will automatically pick up the change, perform the conversion, and publish the new image to `ghcr.io/<owner>/c2w-examples/<image>`.

## How to update images

Images are automatically updated **every week on Sunday at midnight UTC** via a scheduled workflow.
You can also manually trigger an update for all images:

1.  Go to the "Actions" tab in your repository.
2.  Select the **Build and Push Images** workflow.
3.  Click **Run workflow** and select the `main` branch.

This will re-pull the latest tag for each image in `images.txt` (e.g., `alpine:latest`), re-convert it, and push the updated manifest to GHCR.
