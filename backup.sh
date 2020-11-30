#!/bin/bash
  
usage() {
    echo "Usage: $(basename "$0") -t targetsFile [-b backupDestination]"
    echo -e "\nRequired:"
    echo -e "\t-t targetsFile"
    echo -e "\t\tFully qualified targets file name"
    echo -e "\t\tcontaining list of files/folders to backup"
    echo -e "\nOptions:"
    echo -e "\t-b backupDestination"
    echo -e "\t\tDirectory to place backups in"
    echo -e "\t\tDefault: targetsFile directory"
    exit 1
}

# read invocation options
while getopts "b:t:" opt; do
    case "$opt" in
        b) backup_location="$OPTARG";;
        t) targets="$OPTARG";;
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

# create backup root
backup_location="$backup_location/backup_$(date '+%Y-%m-%d_%H.%M')"
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
