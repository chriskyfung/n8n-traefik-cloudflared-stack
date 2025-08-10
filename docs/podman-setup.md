# Podman (Rootless) Setup Guide

This setup can be run using rootless Podman on a Linux host. The following guide explains the necessary host configuration.

### 0. Prerequisite: `podman-compose` Version

It is critical to use a recent version of `podman-compose` (v1.5.0 or newer). The version included in some Linux distributions (e.g., v1.0.6 in Ubuntu 24.04) is outdated and does not integrate properly with modern Podman, causing commands like `podman ps` and `podman volume ls` to fail to show resources.

We recommend installing the latest version manually. A common method is to download the script directly from GitHub, which ensures you have the latest stable version without relying on package managers:

```bash
curl -o /usr/local/bin/podman-compose https://raw.githubusercontent.com/containers/podman-compose/main/podman_compose.py
chmod +x /usr/local/bin/podman-compose
```

### 1. Host Configuration

These steps configure the host environment to allow Traefik to run correctly as a non-root user.

#### Enable Podman Socket

Traefik needs to communicate with the Podman API to detect containers. Enable and start the user-specific Podman socket with the following command:

```bash
systemctl --user enable --now podman.socket
```

#### Allow Binding to Privileged Ports

To allow the Traefik container (running as a non-root user) to bind to standard HTTP and HTTPS ports, you need to adjust a kernel parameter:

```bash
sudo sysctl -w net.ipv4.ip_unprivileged_port_start=80
```

To make this change persistent across reboots, create a configuration file:

```bash
echo "net.ipv4.ip_unprivileged_port_start=80" | sudo tee /etc/sysctl.d/podman-traefik.conf
```

### 2. Certificate Storage (acme.json)

The `podman-compose.yml` file is configured to use a persistent named volume called `traefik_data`. Traefik will automatically create and manage an `acme.json` file within this volume to store your Let's Encrypt SSL certificates. This is handled by the container and requires no manual file creation on the host.

### 3. Podman Commands

Once the host is configured, you can use the following commands to manage the stack.

#### Running with Podman

To start the stack with Podman, use the following command:

```bash
podman-compose -f podman-compose.yml up -d
```

#### Viewing Logs with Podman

Due to a limitation in how `podman-compose` interacts with the Podman socket, it cannot aggregate logs from all services at once. You must view the logs for each service individually.

To view the logs for a specific service, append its name to the command. For example:

```bash
# View logs for the Traefik service
podman-compose -f podman-compose.yml logs -f traefik

# View logs for the n8n service
podman-compose -f podman-compose.yml logs -f n8n

# View logs for the Cloudflare Tunnel service
podman-compose -f podman-compose.yml logs -f cloudflared
```

#### Stopping the Stack with Podman

To stop the n8n stack when using Podman, use the following command:

```bash
podman-compose -f podman-compose.yml down
```
