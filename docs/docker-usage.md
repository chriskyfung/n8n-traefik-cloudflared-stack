# Docker Usage Guide

This document provides the basic commands for running and managing this stack with Docker Compose.

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
