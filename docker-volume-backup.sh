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

# Backup a single volume
_backup_volume() {
    local volume_name=$1
    local timestamp=$2
    local skip_if_empty=$3

    if [ "$skip_if_empty" = true ]; then
        local data_empty=$(docker run --rm -v "${volume_name}:/data" alpine ls -A /data)
        if [ -z "${data_empty}" ]; then
            echo "${volume_name} is empty, skipping backup."
            return
        fi
    fi

    local backup_filename="${volume_name}_${timestamp}.tar.gz"
    local backup_file="${BACKUP_DIR}/${backup_filename}"

    echo "Backing up ${volume_name} to ${backup_file}..."
    docker run --rm -v "${volume_name}:/data" -v "${BACKUP_DIR}:/backup" alpine sh -c 'tar czf "/backup/$1" -C /data . && chmod 600 "/backup/$1"' _ "${backup_filename}"
    if [ $? -ne 0 ]; then
        echo "Backup of ${volume_name} failed!"
        return 1
    fi
    echo "${volume_name} backup successful!"
}

# Backup volumes
backup() {
    read -p "This will stop the n8n and traefik containers if they are running. Are you sure? [y/N] " confirm
    if [[ ! "$confirm" =~ ^[yY]$ ]]; then
        echo "Aborting."
        exit 1
    fi

    local containers_to_check=("${STACK_NAME}_n8n" "${STACK_NAME}_traefik")
    local containers_to_restart=()

    for container in "${containers_to_check[@]}"; do
        if [ -n "$(docker ps -q -f name="^/${container}$" -f status=running)" ]; then
            containers_to_restart+=("${container}")
        fi
    done

    echo "Starting backup..."
    if [ ${#containers_to_restart[@]} -gt 0 ]; then
        echo "Stopping containers: ${containers_to_restart[*]}..."
        docker stop "${containers_to_restart[@]}"
    fi

    mkdir -p "${BACKUP_DIR}"
    local timestamp=$(date +"%Y%m%d_%H%M%S")

    _backup_volume "${STACK_NAME}_n8n_storage" "${timestamp}" false || handle_backup_failure
    _backup_volume "${STACK_NAME}_traefik_data" "${timestamp}" true || handle_backup_failure
    _backup_volume "${STACK_NAME}_n8n_files_storage" "${timestamp}" true || handle_backup_failure

    if [ ${#containers_to_restart[@]} -gt 0 ]; then
        echo "Starting containers: ${containers_to_restart[*]}..."
        docker start "${containers_to_restart[@]}"
    fi
}

handle_backup_failure() {
    echo "A backup step failed. Restoring container state..."
    if [ ${#containers_to_restart[@]} -gt 0 ]; then
        echo "Starting containers: ${containers_to_restart[*]}..."
        docker start "${containers_to_restart[@]}"
    fi
}

# Restore a single volume
_restore_volume() {
    local volume_name=$1
    local descriptive_name=$2

    local latest_backup=$(ls -t "${BACKUP_DIR}/${volume_name}_"*.tar.gz 2>/dev/null | head -n 1)
    if [ -z "${latest_backup}" ]; then
        echo "No ${descriptive_name} backup file found."
    else
        read -p "Restore ${descriptive_name} from ${latest_backup}? [y/N] " confirm
        if [[ "$confirm" =~ ^[yY]$ ]]; then
            clean_volume "${volume_name}"
            echo "Restoring ${volume_name}..."
            local backup_filename=$(basename "${latest_backup}")
            docker run --rm -v "${volume_name}:/data" -v "${BACKUP_DIR}:/backup" alpine tar xzf "/backup/${backup_filename}" -C /data
            if [ $? -eq 0 ]; then
                echo "${descriptive_name} restore successful!"
            else
                echo "${descriptive_name} restore failed!"
                return 1
            fi
        else
            echo "${descriptive_name} restore cancelled."
        fi
    fi
}

# Restore volumes
restore() {
    read -p "This will stop the n8n and traefik containers if they are running. Are you sure? [y/N] " confirm
    if [[ ! "$confirm" =~ ^[yY]$ ]]; then
        echo "Aborting."
        exit 1
    fi

    local containers_to_check=("${STACK_NAME}_n8n" "${STACK_NAME}_traefik")
    local containers_to_restart=()

    for container in "${containers_to_check[@]}"; do
        if [ -n "$(docker ps -q -f name="^/${container}$" -f status=running)" ]; then
            containers_to_restart+=("${container}")
        fi
    done

    echo "Starting restore..."
    if [ ${#containers_to_restart[@]} -gt 0 ]; then
        echo "Stopping containers: ${containers_to_restart[*]}..."
        docker stop "${containers_to_restart[@]}"
    fi

    _restore_volume "${STACK_NAME}_n8n_storage" "n8n" || handle_restore_failure
    _restore_volume "${STACK_NAME}_traefik_data" "Traefik" || handle_restore_failure
    _restore_volume "${STACK_NAME}_n8n_files_storage" "n8n files" || handle_restore_failure

    if [ ${#containers_to_restart[@]} -gt 0 ]; then
        echo "Starting containers: ${containers_to_restart[*]}..."
        docker start "${containers_to_restart[@]}"
    fi
}

handle_restore_failure() {
    if [ ${#containers_to_restart[@]} -gt 0 ]; then
        echo "Starting containers: ${containers_to_restart[*]}..."
        docker start "${containers_to_restart[@]}"
    fi
    exit 1
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
