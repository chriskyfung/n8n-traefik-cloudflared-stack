# Self-Hosted n8n with Cloudflare Zero Trust

This repository contains the configuration to self-host n8n using Docker Compose or Podman, with Traefik as a reverse proxy and secured by Cloudflare Zero Trust.

This setup is based on the excellent tutorial by Kjetil Furas: [Self-Host n8n with Cloudflare Zero Trust and Docker](https://kjetilfuras.com/self-host-n8n-with-cloudflare-zero-trust/).

## Overview

The goal of this setup is to provide a secure, scalable, and easy-to-maintain n8n instance. The key components are:

* **n8n:** The core workflow automation tool.
* **Traefik:** A modern reverse proxy.
* **Cloudflare Tunnel:** To securely expose the n8n instance to the internet without opening firewall ports.

## Getting Started

1. Clone this repository.
2. Follow the instructions in the [original tutorial](https://kjetilfuras.com/self-host-n8n-with-cloudflare-zero-trust/) to set up your Cloudflare Tunnel and obtain the necessary credentials.
3. Create a `.env` file and populate it with your configuration. You can use the `.env.example` file as a template.
4. Proceed to the appropriate documentation for your container engine.

## Documentation

Detailed setup and usage instructions are located in the `/docs` directory:

*   **[Docker Usage Guide](./docs/docker-usage.md)**: For running the stack with Docker Compose.
*   **[Podman (Rootless) Setup Guide](./docs/podman-setup.md)**: For a full setup guide on a rootless Podman host.
*   **[Traffic Security Analysis](./docs/traffic-security-analysis.md)**: A breakdown of the security for ingress and egress traffic.
*   **[Changelog](./CHANGELOG.md)**: For a full list of changes from the original tutorial and ongoing updates.

## Security

This project is designed with security in mind. For details on the security model and how to report vulnerabilities, please see the **[Security Policy](./SECURITY.md)**.

## Attribution

This project is based on the excellent tutorial by Kjetil Furas. If you use this project as a starting point, a link back to this repository is appreciated as a courtesy.

## License

This project is licensed under the MIT License. See the [LICENSE](./LICENSE) file for details.
