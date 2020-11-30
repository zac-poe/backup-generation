#!/bin/bash

backup_prefix='backup_'

usage() {
    echo "Usage: $(basename "$0") -t targetsFile [-b backupDestination] [-m maxBackups]"
    echo -e "\nRequired:"
    echo -e "\t-t targetsFile"
    echo -e "\t\tFully qualified targets file name"
    echo -e "\t\tcontaining list of files/folders to backup"
    echo -e "\nOptions:"
    echo -e "\t-b backupDestination"
    echo -e "\t\tDirectory to place backups in"
    echo -e "\t\tDefault: targetsFile directory"
    echo -e "\t-m maxBackups"
    echo -e "\t\tMaximum number of backups to retain"
    echo -e "\t\tDefault: unlimited"
    exit 1
}

# read invocation options
while getopts "b:t:m:" opt; do
    case "$opt" in
        b) backup_location="$OPTARG";;
        t) targets="$OPTARG";;
        m) max_backups="$OPTARG" ;;
        *) usage;;
    esac
done
OPTIND=1

# simple support for usage like 'this.sh help', or to prevent unintentional misuse with flags
if [[ ${#1} -gt 0 && $(printf -- "$1" | grep -c '^-') -le 0 ]]; then
    usage
fi

# validate invocation
if [[ -z "$targets" ]]; then
    usage
elif [[ ! -a "$targets" ]]; then
    echo "File not found: $targets"
    exit 1
fi
if [[ -z "$backup_location" ]]; then
    backup_location="$(cd "$(dirname "$targets")" && pwd)"
fi
if [[ ! -d "$backup_location" ]]; then
    echo "Backup directory not found: $backup_location"
    exit 1
fi
if [[ ! -z "$max_backups" && $(echo "$max_backups" | grep -c '^[1-9][0-9]*$') -le 0 ]]; then
    usage
fi

# remove previous backups
if [[ ! -z "$max_backups" ]]; then
    while [[ $(ls "$backup_location" | grep -c "^$backup_prefix") -ge "$max_backups" ]]; do
        last_backup="$(ls -t "$backup_location" | grep "^$backup_prefix" | head -n 1)"
        rm -r "$backup_location/$last_backup/"
        if [[ $? -ne 0 ]]; then
            echo "Failed to remove former backup: $last_backup"
            exit 1
        fi
    done
fi

# create backup directory
backup_location="$backup_location/$backup_prefix$(date '+%Y-%m-%d_%H.%M')"
mkdir -p "$backup_location/"
if [[ $? -ne 0 ]]; then
    echo "Unable to create backup destination: $backup"
fi

# generate new backups
echo "Creating backup at $backup_location..."
while read line; do
    # ignore comments & non-existent files
    if [ $(echo "$line" | grep -Ec '\s*#') -le 0 ] && [ -e "$line" ]; then
        # remove any trailing slashes
        line="$(echo "$line" | sed 's:/$::')"

        echo -e "\tArchiving $line..."
        tar --directory="${line%/*}" -czf "$backup_location/${line##*/}.tar.gz" "${line##*/}"
        if [[ $? -ne 0 ]]; then
            echo "Failed while archiving target: $line"
            exit 1
        fi
    fi
done < "$targets"

echo "Backup generation complete."
