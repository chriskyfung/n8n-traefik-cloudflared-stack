# Changelog

This file documents the changes made to the original project from the [tutorial by Kjetil Furas](https://kjetilfuras.com/self-host-n8n-with-cloudflare-zero-trust/).

## [1.2.0] - 2026-01-28

### Added

-   **Backup and Restore**: Introduced `docker-volume-backup.sh` for creating and restoring data for n8n and Traefik, enhancing data management capabilities.

### Changed

-   **Portability & Naming**:
    -   Updated all services to use dynamic container names prefixed with `${COMPOSE_PROJECT_NAME}` to prevent naming conflicts across multiple stacks.
    -   Explicitly named the `n8n-net` network to avoid conflicts in multi-project Docker and Podman environments.
-   **Security**: Removed direct host port mappings for Traefik's internal entrypoints (`8082`, `8083`), reducing the host's external attack surface.
-   **Code of Conduct**: Updated the abuse reporting method to use the repository's private "Report a vulnerability" feature, ensuring a secure and confidential channel.

## [1.1.0] - 2025-09-15

### Security

-   **Traefik Hardening**: Switched from Docker/Podman socket to a file-based provider (`./traefik/dynamic_conf.yml`) to reduce attack surface and enhance security by preventing direct access to the container daemon.

### Added

-   **Security Policy (`SECURITY.md`)**: Added a formal security policy with instructions for reporting vulnerabilities.
-   **Traffic Security Analysis (`docs/traffic-security-analysis.md`)**: New documentation detailing the data flow and security measures at each layer of the stack.

### Fixed

-   **Traefik Healthcheck**: Resolved intermittent healthcheck failures by adjusting the check interval and timeout values.

### Changed

-   **Pinned Image Versions**: Pinned the `n8n` image to the `stable` tag and `traefik` to `v3.5` for more stable and predictable deployments.
-   **Synchronized Compose Files**: Updated `podman-compose.yml` to align with the latest improvements in `docker-compose.yml`.
-   **Podman Documentation**: Overhauled `docs/podman-setup.md` to reflect the new file-based configuration for Traefik.

## [1.0.0] - 2025-08-13

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
