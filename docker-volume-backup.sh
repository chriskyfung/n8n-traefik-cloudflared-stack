#!/bin/bash

# Default stack name
STACK_NAME=""
# Default backup directory
BACKUP_DIR=$(pwd)

# --- Functions ---

# Show usage
usage() {
    echo "Usage: $0 [-s stack_name] [-d backup_dir] [backup|restore]"
    echo "  -s stack_name: Set the stack name (defaults to the parent directory name)."
    echo "  -d backup_dir: Set the backup directory (defaults to the current directory)."
    echo "  backup: Backup n8n and traefik volumes."
    echo "  restore: Restore n8n and traefik volumes from the latest backup."
    exit 1
}

# Clean a volume
clean_volume() {
    local volume_name=$1
    read -p "Are you sure you want to clean the volume '${volume_name}'? This will delete all data in it. [y/N] " confirm
    if [[ "$confirm" =~ ^[yY]$ ]]; then
        echo "Cleaning volume ${volume_name}..."
        docker run --rm -v "${volume_name}:/data" alpine sh -c "find /data -mindepth 1 -delete"
        if [ $? -eq 0 ]; then
            echo "Volume cleaned successfully."
        else
            echo "Failed to clean volume."
            exit 1
        fi
    else
        echo "Skipping volume cleaning."
    fi
}

# Backup volumes
backup() {
    read -p "This will stop the n8n and traefik containers. Are you sure? [y/N] " confirm
    if [[ ! "$confirm" =~ ^[yY]$ ]]; then
        echo "Aborting."
        exit 1
    fi

    echo "Starting backup..."
    echo "Stopping containers..."
    docker stop "${STACK_NAME}_n8n" "${STACK_NAME}_traefik"

    mkdir -p "${BACKUP_DIR}"
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local n8n_volume_name="${STACK_NAME}_n8n_storage"
    local traefik_volume_name="${STACK_NAME}_traefik_data"
    local n8n_backup_filename="${n8n_volume_name}_${timestamp}.tar.gz"
    local traefik_backup_filename="${traefik_volume_name}_${timestamp}.tar.gz"
    local n8n_backup_file="${BACKUP_DIR}/${n8n_backup_filename}"
    local traefik_backup_file="${BACKUP_DIR}/${traefik_backup_filename}"

    echo "Backing up ${n8n_volume_name} to ${n8n_backup_file}..."
    docker run --rm -v "${n8n_volume_name}:/data" -v "${BACKUP_DIR}:/backup" alpine tar czf "/backup/${n8n_backup_filename}" -C /data .
    if [ $? -ne 0 ]; then
        echo "Backup of ${n8n_volume_name} failed!"
        docker start "${STACK_NAME}_n8n" "${STACK_NAME}_traefik"
        exit 1
    fi
    echo "n8n backup successful!"

    local traefik_data_empty=$(docker run --rm -v "${traefik_volume_name}:/data" alpine ls -A /data)
    if [ -z "${traefik_data_empty}" ]; then
        echo "Traefik data volume is empty, skipping backup."
    else
        echo "Backing up ${traefik_volume_name} to ${traefik_backup_file}..."
        docker run --rm -v "${traefik_volume_name}:/data" -v "${BACKUP_DIR}:/backup" alpine tar czf "/backup/${traefik_backup_filename}" -C /data .
        if [ $? -ne 0 ]; then
            echo "Backup of ${traefik_volume_name} failed!"
            docker start "${STACK_NAME}_n8n" "${STACK_NAME}_traefik"
            exit 1
        fi
        echo "Traefik backup successful!"
    fi

    echo "Starting containers..."
    docker start "${STACK_NAME}_n8n" "${STACK_NAME}_traefik"
}

# Restore volumes
restore() {
    read -p "This will stop the n8n and traefik containers. Are you sure? [y/N] " confirm
    if [[ ! "$confirm" =~ ^[yY]$ ]]; then
        echo "Aborting."
        exit 1
    fi

    echo "Starting restore..."
    echo "Stopping containers..."
    docker stop "${STACK_NAME}_n8n" "${STACK_NAME}_traefik"

    local n8n_volume_name="${STACK_NAME}_n8n_storage"
    local traefik_volume_name="${STACK_NAME}_traefik_data"

    # Restore n8n
    local latest_n8n_backup=$(ls -t "${BACKUP_DIR}/${n8n_volume_name}_"*.tar.gz 2>/dev/null | head -n 1)
    if [ -z "${latest_n8n_backup}" ]; then
        echo "No n8n backup file found."
    else
        read -p "Restore n8n from ${latest_n8n_backup}? [y/N] " confirm_n8n
        if [[ "$confirm_n8n" =~ ^[yY]$ ]]; then
            clean_volume "${n8n_volume_name}"
            echo "Restoring ${n8n_volume_name}..."
            local backup_filename=$(basename "${latest_n8n_backup}")
            docker run --rm -v "${n8n_volume_name}:/data" -v "${BACKUP_DIR}:/backup" alpine tar xzf "/backup/${backup_filename}" -C /data
            if [ $? -eq 0 ]; then
                echo "n8n restore successful!"
            else
                echo "n8n restore failed!"
                exit 1
            fi
        else
            echo "n8n restore cancelled."
        fi
    fi

    # Restore Traefik
    local latest_traefik_backup=$(ls -t "${BACKUP_DIR}/${traefik_volume_name}_"*.tar.gz 2>/dev/null | head -n 1)
    if [ -z "${latest_traefik_backup}" ]; then
        echo "No Traefik backup file found."
    else
        read -p "Restore Traefik from ${latest_traefik_backup}? [y/N] " confirm_traefik
        if [[ "$confirm_traefik" =~ ^[yY]$ ]]; then
            clean_volume "${traefik_volume_name}"
            echo "Restoring ${traefik_volume_name}..."
            local backup_filename=$(basename "${latest_traefik_backup}")
            docker run --rm -v "${traefik_volume_name}:/data" -v "${BACKUP_DIR}:/backup" alpine tar xzf "/backup/${backup_filename}" -C /data
            if [ $? -eq 0 ]; then
                echo "Traefik restore successful!"
            else
                echo "Traefik restore failed!"
                exit 1
            fi
        else
            echo "Traefik restore cancelled."
        fi
    fi

    echo "Starting containers..."
    docker start "${STACK_NAME}_n8n" "${STACK_NAME}_traefik"
}

# --- Main ---

while getopts ":s:d:" opt; do
  case ${opt} in
    s )
      STACK_NAME=$OPTARG
      ;;
    d )
      BACKUP_DIR=$OPTARG
      ;;
    ? )
      usage
      ;;
  esac
done
shift $((OPTIND -1))

# Remove trailing slash from backup dir
BACKUP_DIR=${BACKUP_DIR%/}

if [ -z "${STACK_NAME}" ]; then
    SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
    STACK_NAME="$(basename "$SCRIPT_DIR")"
fi

COMMAND=$1
if [ -z "${COMMAND}" ]; then
    usage
fi

case "$COMMAND" in
    backup)
        backup
        ;;
    restore)
        restore
        ;;
    *)
        usage
        ;;
esac
