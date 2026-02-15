# Backup and Restore

This document describes how to use the `docker-volume-backup.sh` script to backup and restore your n8n and Traefik data volumes.

**Note:** This script is designed for use with **Docker and Docker volumes**. It will not work with Podman out of the box. For Podman, please refer to the [Podman Users](#podman-users) section below.

## Overview

The `docker-volume-backup.sh` script provides a convenient way to create backups of your important data and restore it when needed. It is designed to be run from the root of your `n8n-stack` project directory.

The script automates the process of stopping the running containers, creating the backup, and restarting the containers.

## Prerequisites

- Docker must be installed and running.
- The script must be executable. If it is not, run the following command:
  ```bash
  chmod +x docker-volume-backup.sh
  ```

## How it Works

The script uses the stack name (either provided with `-s` or defaulted from the directory name) to identify the volumes and containers to manage. The container names are expected to be in the format `<stack-name>_<service-name>` (e.g., `n8n-stack_n8n`).

### Backup Process

1.  **Confirmation:** The script will ask for confirmation before stopping the containers.
2.  **Stop Containers:** It stops the `n8n` and `traefik` containers to ensure data consistency.
3.  **Create Backups:** It creates timestamped `.tar.gz` archives of the `n8n_storage`, `n8n_files_storage`, and `traefik_data` volumes. Backups for the `traefik_data` and `n8n_files_storage` volumes will be skipped if they are empty.
4.  **Restart Containers:** It restarts the stopped containers.

### Restore Process

1.  **Confirmation:** The script will ask for confirmation before stopping the containers.
2.  **Stop Containers:** It stops the `n8n` and `traefik` containers to safely perform the restore.
3.  **Restore Volumes:** For each volume, it prompts for confirmation to restore. It also offers to clean the volume before restoring.
4.  **Restart Containers:** It restarts the `n8n` and `traefik` containers.

## Usage

```bash
./docker-volume-backup.sh [-s stack_name] [-d backup_dir] [command]
```

### Commands

- `backup`: Creates a backup of the `n8n_storage` and `traefik_data` volumes.
- `restore`: Restores the `n8n_storage`, `n8n_files_storage`, and `traefik_data` volumes from the latest backup.

### Options

- `-s stack_name`: Specifies the name of the stack. If not provided, it defaults to the name of the project's root directory (`n8n-stack`). This name is used to identify both the volumes and the containers.
- `-d backup_dir`: Specifies the directory where backups will be stored and restored from. Defaults to the current directory.

### Backup

To create a backup, run the following command:

```bash
./docker-volume-backup.sh backup
```

The script will ask for confirmation, then stop the containers, create the backups, and restart the containers. The backup files will be created in the current directory (or the directory specified with `-d`).

### Restore

To restore from the latest backup, run the following command:

```bash
./docker-volume-backup.sh restore
```

The script will first ask for confirmation to stop the containers. Then, for each volume, it will prompt for confirmation to restore from the latest backup. It will also ask if you want to clean the volume (delete its current contents) before restoring. After the restore process is complete, the containers will be restarted.

**Warning:** Restoring is a destructive operation. Make sure you have a backup of your current data if you need it.

## Podman Users

The `docker-volume-backup.sh` script is not compatible with Podman. Podman users should use the native `podman volume` commands to manage their volume backups.

- **`podman volume export`**: Exports the contents of a volume to a tarball.
  - [Official Documentation](https://docs.podman.io/en/latest/markdown/podman-volume-export.1.html)
- **`podman volume import`**: Imports the contents of a tarball into a volume.
  - [Official Documentation](https://docs.podman.io/en/latest/markdown/podman-volume-import.1.html)

You can adapt the logic from the `docker-volume-backup.sh` script to create your own backup solution using these Podman commands.
