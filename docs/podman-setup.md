# Podman (Rootless) Setup Guide

This setup can be run using rootless Podman on a Linux host. The following guide explains the necessary host configuration.

### 0. Prerequisite: `podman-compose` on Ubuntu 24.04

On Ubuntu 24.04, it is critical to use `podman-compose` v1.5.0 or newer. The version included in the `apt` repository (v1.0.6) is outdated and does not integrate properly with modern Podman, causing commands like `podman ps` and `podman volume ls` to fail to show resources.

Follow these steps to install the `apt` version and then upgrade it manually:

1.  **Install the `apt` package**:
    ```bash
    sudo apt-get update
    sudo apt-get install podman-compose
    ```

2.  **Upgrade to the latest version**:
    Download the latest script from GitHub to ensure you have a modern, a stable version:
    ```bash
    curl -o /usr/local/bin/podman-compose https://raw.githubusercontent.com/containers/podman-compose/main/podman_compose.py
    chmod +x /usr/local/bin/podman-compose
    ```

3.  **Set the provider environment variable**:
    To ensure the system uses the manually installed version, add the following line to your shell configuration file (e.g., `~/.bashrc`, `~/.zshrc`):
    ```bash
    export PODMAN_COMPOSE_PROVIDER="/usr/local/bin/podman-compose"
    ```
    Remember to reload your shell or run `source ~/.bashrc` (or equivalent) for the changes to take effect.

### 1. Configuration

The stack's behavior is controlled by environment variables and the Traefik configuration files.

#### Environment Variables

Create a `.env` file in the root of the project to set your configuration. You can use `.env.example` as a template.

The following variables allow you to customize the ports exposed by the Traefik reverse proxy:

-   `N8N_UI_PORT`: Sets the external port for the n8n UI. Defaults to `8082`.
-   `N8N_WEBHOOK_PORT`: Sets the external port for receiving n8n webhooks. Defaults to `8083`.

#### Traefik File-Based Configuration

This stack uses a file-based configuration for Traefik, located in the `./traefik` directory. This approach is more secure than providing the Traefik container with access to the Podman socket.

#### Certificate Storage (acme.json)

The `podman-compose.yml` file is configured to use a persistent named volume called `traefik_data`. Traefik will automatically create and manage an `acme.json` file within this volume to store your Let's Encrypt SSL certificates. This is handled by the container and requires no manual file creation on the host.

### 2. Running the Stack

Once the prerequisites are met, you can use the following commands to manage the stack.

#### A Note on `podman-remote`

Because this setup uses a local directory bind mount (`./traefik`) for its configuration, you must run `podman-compose` on the same machine that is running the Podman service.

If you are managing a remote machine, first ensure the entire project directory is present on the remote machine (e.g., via `git clone` or `scp`), and then run all commands directly on that machine (e.g., over an SSH session).

#### Starting the Stack

To start all services in detached mode, run the following command:

```bash
podman-compose -f podman-compose.yml up -d
```

#### Viewing Logs

`podman-compose` does not currently support aggregating logs from all services at once. You must view the logs for each service individually.

To view the logs for a specific service, append its name to the command. For example:

```bash
# View logs for the Traefik service
podman-compose -f podman-compose.yml logs -f traefik

# View logs for the n8n service
podman-compose -f podman-compose.yml logs -f n8n

# View logs for the Cloudflare Tunnel service
podman-compose -f podman-compose.yml logs -f cloudflared
```

#### Stopping the Stack

To stop the n8n stack, use the following command:

```bash
podman-compose -f podman-compose.yml down
```
