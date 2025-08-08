# Self-Hosted n8n with Cloudflare Zero Trust

This repository contains the configuration to self-host n8n using Docker Compose, with Traefik as a reverse proxy and secured by Cloudflare Zero Trust.

This setup is based on the excellent tutorial by Kjetil Furas: [Self-Host n8n with Cloudflare Zero Trust and Docker](https://kjetilfuras.com/self-host-n8n-with-cloudflare-zero-trust/).

## Overview

The goal of this setup is to provide a secure, scalable, and easy-to-maintain n8n instance. The key components are:

* **n8n:** The core workflow automation tool.
* **Traefik:** A modern reverse proxy.
* **PostgreSQL:** A robust database for n8n data.
* **Cloudflare Tunnel:** To securely expose the n8n instance to the internet without opening firewall ports.
* **Cloudflare Access:** To protect the n8n UI login page.

## Getting Started

1. Clone this repository.
2. Follow the instructions in the [original tutorial](https://kjetilfuras.com/self-host-n8n-with-cloudflare-zero-trust/) to set up your Cloudflare Tunnel and obtain the necessary credentials.
3. Create a `.env` file and populate it with your configuration. You can use the `.env.example` file in the tutorial as a template.
4. Run `docker compose up -d` to start the services.

For a detailed explanation of each step, please refer to the [original tutorial](https://kjetilfuras.com/self-host-n8n-with-cloudflare-zero-trust/).

## Usage

### Running the n8n Stack

To start the n8n stack, run the following command in your terminal:

```bash
docker compose up -d
```

This will start all the services in detached mode.

### Viewing Logs

To view the logs of the running services, you can use the following command:

```bash
docker compose logs -f
```

### Stopping the Stack

To stop the n8n stack, use the following command:

```bash
docker compose down
```

## Changes from the original tutorial

This repository has a few changes from the original tutorial:

*   The Traefik image has been updated to `v3.5.0`.
*   A `.dockerignore` file has been added to optimize the Docker build context.
*   This `README.md` and a `CHANGELOG.md` have been added for better documentation.

For a full list of changes, please see the [`CHANGELOG.md`](CHANGELOG.md) file.
