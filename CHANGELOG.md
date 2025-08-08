# Changelog

This file documents the changes made to the original project from the [tutorial by Kjetil Furas](https://kjetilfuras.com/self-host-n8n-with-cloudflare-zero-trust/).

## Added

* `.dockerignore`: To exclude unnecessary files from the Docker build context.
* `README.md`: This file, providing an overview of the project and linking to the original tutorial.
* `CHANGELOG.md`: This file, to track changes.

## Changed

* `docker-compose.yml`:
  * Updated the Traefik image from `v2.10` to `v3.5.0` for the latest features and security updates.
* `README.Docker.md`: Updated with instructions on how to run the stack using `docker compose`.
