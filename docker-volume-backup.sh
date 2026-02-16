#!/bin/bash

# Default stack name
STACK_NAME=""
# Default backup directory
BACKUP_DIR=$(pwd)

# --- Colors ---
COLOR_RESET='\033[0m'
COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'
COLOR_CYAN='\033[0;36m'

# --- Functions ---

# Show usage
usage() {
    echo -e "Usage: $0 [-s stack_name] [-d backup_dir] [backup|restore]"
    echo -e "  -s stack_name: Set the stack name (defaults to the parent directory name)."
    echo -e "  -d backup_dir: Set the backup directory (defaults to the current directory)."
    echo -e "  ${COLOR_CYAN}backup${COLOR_RESET}:  Backup n8n and traefik volumes."
    echo -e "  ${COLOR_CYAN}restore${COLOR_RESET}: Restore n8n and traefik volumes from the latest backup."
    exit 1
}

# Clean a volume
clean_volume() {
    local volume_name=$1
    read -p "$(echo -e "${COLOR_YELLOW}Are you sure you want to clean the volume '${volume_name}'? This will delete all data in it. [y/N] ${COLOR_RESET}")" confirm
    if [[ "$confirm" =~ ^[yY]$ ]]; then
        echo -e "${COLOR_CYAN}Cleaning volume ${volume_name}...${COLOR_RESET}"
        docker run --rm -v "${volume_name}:/data" alpine sh -c "find /data -mindepth 1 -delete"
        if [ $? -eq 0 ]; then
            echo -e "${COLOR_GREEN}Volume cleaned successfully.${COLOR_RESET}"
        else
            echo -e "${COLOR_RED}Failed to clean volume.${COLOR_RESET}"
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
            echo -e "${volume_name} is empty, skipping backup."
            return
        fi
    fi

    local backup_filename="${volume_name}_${timestamp}.tar.gz"
    local backup_file="${BACKUP_DIR}/${backup_filename}"

    echo -e "${COLOR_CYAN}Backing up ${volume_name} to ${backup_file}...${COLOR_RESET}"
    docker run --rm -v "${volume_name}:/data" -v "${BACKUP_DIR}:/backup" alpine sh -c 'tar czf "/backup/$1" -C /data . && chmod 600 "/backup/$1"' _ "${backup_filename}"
    if [ $? -ne 0 ]; then
        echo -e "${COLOR_RED}Backup of ${volume_name} failed!${COLOR_RESET}"
        return 1
    fi
    echo -e "${COLOR_GREEN}${volume_name} backup successful!${COLOR_RESET}"
}

# Core backup logic
_backup_core() {
    mkdir -p "${BACKUP_DIR}"
    local timestamp=$(date +"%Y%m%d_%H%M%S")

    _backup_volume "${STACK_NAME}_n8n_storage" "${timestamp}" false || return 1
    _backup_volume "${STACK_NAME}_traefik_data" "${timestamp}" true || return 1
    _backup_volume "${STACK_NAME}_n8n_files_storage" "${timestamp}" true || return 1
}

# Restore a single volume
_restore_volume() {
    local volume_name=$1
    local descriptive_name=$2

    local latest_backup=$(ls -t "${BACKUP_DIR}/${volume_name}_"*.tar.gz 2>/dev/null | head -n 1)
    if [ -z "${latest_backup}" ]; then
        echo -e "No ${descriptive_name} backup file found."
    else
        read -p "$(echo -e "${COLOR_YELLOW}Restore ${descriptive_name} from ${latest_backup}? [y/N] ${COLOR_RESET}")" confirm
        if [[ "$confirm" =~ ^[yY]$ ]]; then
            clean_volume "${volume_name}"
            echo -e "${COLOR_CYAN}Restoring ${volume_name}...${COLOR_RESET}"
            local backup_filename=$(basename "${latest_backup}")
            docker run --rm -v "${volume_name}:/data" -v "${BACKUP_DIR}:/backup" alpine tar xzf "/backup/${backup_filename}" -C /data
            if [ $? -eq 0 ]; then
                echo -e "${COLOR_GREEN}${descriptive_name} restore successful!${COLOR_RESET}"
            else
                echo -e "${COLOR_RED}${descriptive_name} restore failed!${COLOR_RESET}"
                return 1
            fi
        else
            echo -e "${descriptive_name} restore cancelled."
        fi
    fi
}

# Core restore logic
_restore_core() {
    _restore_volume "${STACK_NAME}_n8n_storage" "n8n" || return 1
    _restore_volume "${STACK_NAME}_traefik_data" "Traefik" || return 1
    _restore_volume "${STACK_NAME}_n8n_files_storage" "n8n files" || return 1
}

# Wrapper function to manage container lifecycle for an operation
execute_with_container_management() {
    local operation_name=$1
    local core_function=$2

    read -p "$(echo -e "${COLOR_YELLOW}This will stop the n8n and traefik containers if they are running. Are you sure? [y/N] ${COLOR_RESET}")" confirm
    if [[ ! "$confirm" =~ ^[yY]$ ]]; then
        echo -e "${COLOR_RED}Aborting.${COLOR_RESET}"
        exit 1
    fi

    local containers_to_restart=()
    for container in "${STACK_NAME}_n8n" "${STACK_NAME}_traefik"; do
        if [ -n "$(docker ps -q -f name="^/${container}$" -f status=running)" ]; then
            containers_to_restart+=("${container}")
        fi
    done

    echo -e "${COLOR_CYAN}Starting ${operation_name}...${COLOR_RESET}"
    if [ ${#containers_to_restart[@]} -gt 0 ]; then
        echo -e "Stopping containers: ${containers_to_restart[*]}..."
        docker stop "${containers_to_restart[@]}"
    fi

    # Execute the core logic (backup or restore)
    local operation_failed=0
    if ! "${core_function}"; then
        echo -e "${COLOR_RED}A ${operation_name} step failed. Restoring container state...${COLOR_RESET}"
        operation_failed=1
    fi

    if [ ${#containers_to_restart[@]} -gt 0 ]; then
        echo -e "Starting containers: ${containers_to_restart[*]}..."
        docker start "${containers_to_restart[@]}"
    fi

    if [ ${operation_failed} -ne 0 ]; then
        exit 1
    fi

    echo -e "${COLOR_GREEN}${operation_name^} completed successfully.${COLOR_RESET}"
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
        execute_with_container_management "backup" "_backup_core"
        ;;
    restore)
        execute_with_container_management "restore" "_restore_core"
        ;;
    *)
        usage
        ;;
esac
