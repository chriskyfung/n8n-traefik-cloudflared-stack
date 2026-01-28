# Docker Usage Guide

This document provides the basic commands for running and managing this stack with Docker Compose.

### Configuration

The stack is configured using environment variables defined in the `.env` file at the root of the project. You can copy the `.env.example` file to create your own `.env` file.

The following variables allow you to customize the ports exposed by the Traefik reverse proxy:

-   `N8N_UI_PORT`: Sets the external port for the n8n UI. Defaults to `8082`.
-   `N8N_WEBHOOK_PORT`: Sets the external port for receiving n8n webhooks. Defaults to `8083`.

### Running the n8n Stack

To start all services in detached mode, run the following command in your terminal:

```bash
docker compose up -d
```

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
