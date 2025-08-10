# Changelog

This file documents the changes made to the original project from the [tutorial by Kjetil Furas](https://kjetilfuras.com/self-host-n8n-with-cloudflare-zero-trust/).

## [Unreleased]

### Added

-   **Podman Support**: Added `podman-compose.yml` to enable running the stack with Podman.
-   **Documentation Directory (`/docs`)**: Created a new directory for detailed documentation.
    -   `/docs/podman-setup.md`: A comprehensive guide for setting up and running the stack on a rootless Podman host.
    -   `/docs/docker-usage.md`: A guide for Docker operational commands.
-   **Project Files**:
    -   `LICENSE`: Added an MIT License for the project.
    -   `CONTRIBUTING.md`: Added guidelines for contributors.
    -   `CODE_OF_CONDUCT.md`: Added a community code of conduct.
-   `.dockerignore`: To exclude unnecessary files from the Docker build context.

### Changed

-   **`README.md`**: Overhauled the main README to be a concise project overview, with links to the detailed guides in the `/docs` directory and new boilerplate files.
-   **`docker-compose.yml`**: Updated the Traefik image from `v2.10` to `v3.5.0` for the latest features and security updates.