#!/bin/bash
# snap-sync
# https://github.com/wesbarnett/snap-sync
# Copyright (C) 2016, 2017 James W. Barnett

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,

# -------------------------------------------------------------------------

# Takes snapshots of each snapper configuration. It then sends the snapshot to
# a location on an external drive. After the initial transfer, it does
# incremental snapshots on later calls. It's important not to delete the
# snapshot created on your system since that will be used to determine the
# difference for the next incremental snapshot.

set -o errtrace

version="0.5"
name="snap-sync"

# The following line is modified by the Makefile or
# find_snapper_config script
SNAPPER_CONFIG=/etc/conf.d/snapper

TMPDIR=$(mktemp -d)
PIPE=$TMPDIR/$progname.out
mkfifo $PIPE
systemd-cat -t "$progname" < $PIPE &
exec 3>$PIPE

donotify=0
which notify-send &> /dev/null
if [[ $? -ne 0 ]]; then
    donotify=1
fi

notify() {
    for u in $(users | sed 's/ /\n/' | sort -u); do
        sudo -u $u DISPLAY=:0 \
        DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(sudo -u $u id -u)/bus \
        notify-send -a $progname "$1" "$2" --icon="dialog-$3"
    done
}

notify_info() {
    if [[ $donotify -eq 0 ]]; then
        notify "$1" "$2" "information"
    else
        printf "$1: $2\n"
    fi
}

notify_error() {
    if [[ $donotify -eq 0 ]]; then
        notify "$1" "$2" "error"
    else
        printf "$1: $2\n"
    fi
}

error() {
    printf "==> ERROR: %s\n" "$@"
    notify_error 'Error' 'Check journal for more information.'
} >&2

die() {
    error "$@"
    exit 1
}

traperror() {
    printf "Exited due to error on line %s.\n" $1
    printf "exit status: %s\n" "$2"
    printf "command: %s\n" "$3"
    printf "bash line: %s\n" "$4"
    printf "function progname: %s\n" "$5"
    exit 1
}

trapkill() {
    die "Exited due to user intervention."
}

trap 'traperror ${LINENO} $? "$BASH_COMMAND" $BASH_LINENO "${FUNCPROGNAME[@]}"' ERR
trap trapkill SIGTERM SIGINT

usage() {
  cat <<EOF
$progname $version
Usage: $progname [options]

Options:
 -d, --description <desc> Change the snapper description. Default: "latest incremental backup"
 -c, --config <config>    Specify the snapper configuration to use. Otherwise will perform for each snapper
                          configuration. Can list multiple configurations within quotes, space-separated
                          (e.g. -c "root home").
 -n, --noconfirm          Do not ask for confirmation for each configuration. Will still prompt for backup
                          directory name on first backup.
 -u, --UUID <UUID>        Specify the UUID of the mounted BTRFS subvolume to back up to. Otherwise will prompt.
                          If multiple mount points are found with the same UUID, will prompt user.
 -s, --subvolid <subvlid> Specify the subvolume id of the mounted BTRFS subvolume to back up to. Defaults to 5.
     --remote <address>   Send the snapshot backup to a remote machine. The snapshot will be sent via ssh. You 
                          should specify the remote machine's hostname or ip address. The 'root' user must be 
                          permitted to login on the remote machine.
EOF
}


ssh=""
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -d|--description)
            description="$2"
            shift 2
        ;;
        -c|--config)
            selected_configs="$2"
            shift 2
        ;;
        -u|--UUID)
            uuid_cmdline="$2"
            shift 2
        ;;
        -s|--subvolid)
            subvolid_cmdline="$2"
            shift 2
        ;;
        -n|--noconfirm)
            noconfirm="yes"
            shift
        ;;
        -h|--help)
            usage
            exit 1
        ;;
	    --remote)
            remote=$2
            ssh="ssh $remote"
            shift 2
	    ;;
        *)
            die "Unknown option: $key\nRun '$progname -h' for valid options.\n"
        ;;
    esac
done

[[ $EUID -ne 0 ]] && die "Script must be run as root."
! [[ -f $SNAPPER_CONFIG ]] && die "$SNAPPER_CONFIG does not exist."

description=${description:-"latest incremental backup"}
uuid_cmdline=${uuid_cmdline:-"none"}
subvolid_cmdline=${subvolid_cmdline:-"5"}
noconfirm=${noconfirm:-"no"}

if [[ "$uuid_cmdline" != "none" ]]; then
    if [[ -z $ssh ]]; then
        notify_info "Backup started" "Starting backups to $uuid_cmdline subvolid=$subvolid_cmdline..."
    else
        notify_info "Backup started" "Starting backups to $uuid_cmdline subvolid $subvolid_cmdline at $remote..."
    fi
else
    if [[ -z $ssh ]]; then
        notify_info "Backup started" "Starting backups. Use command line menu to select disk."
    else
        notify_info "Backup started" "Starting backups. Use command line menu to select disk on $remote."
    fi
fi

if [[ "$(findmnt -n -v --target / -o FSTYPE)" == "btrfs" ]]; then
    EXCLUDE_UUID=$(findmnt -n -v -t btrfs --target / -o UUID)
    TARGETS=$($ssh findmnt -n -v -t btrfs -o UUID,TARGET --list | grep -v $EXCLUDE_UUID | awk '{print $2}')
    UUIDS=$($ssh findmnt -n -v -t btrfs -o UUID,TARGET --list | grep -v $EXCLUDE_UUID | awk '{print $1}')
else
    TARGETS=$($ssh findmnt -n -v -t btrfs -o TARGET --list)
    UUIDS=$($ssh findmnt -n -v -t btrfs -o UUID --list)
fi

declare -a TARGETS_ARRAY
declare -a UUIDS_ARRAY
declare -a SUBVOLIDS_ARRAY

i=0
for x in $TARGETS; do
    SUBVOLIDS_ARRAY[$i]=$(btrfs subvolume show $x | awk '/Subvolume ID:/ { print $3 }')
    TARGETS_ARRAY[$i]=$x
    i=$((i+1))
done

i=0
disk=-1
disk_count=0
for x in $UUIDS; do
    UUIDS_ARRAY[$i]=$x
    if [[ "$x" == "$uuid_cmdline" && ${SUBVOLIDS_ARRAY[$((i))]} == "$subvolid_cmdline" ]]; then
        disk=$i
        disk_count=$(($disk_count+1))
    fi
    i=$((i+1))
done

if [[ "${#UUIDS_ARRAY[$@]}" -eq 0 ]]; then
    die "No external btrfs subvolumes found to backup to."
fi

if [[ "$disk_count" > 1 ]]; then
    printf "Multiple mount points were found with UUID %s and subvolid %s.\n" "$uuid_cmdline" "$subvolid_cmdline"
    disk="-1"
fi

if [[ "$disk" == -1 ]]; then
    if [[ "$disk_count" == 0 && "$uuid_cmdline" != "none" ]]; then
        error "A device with UUID $uuid_cmdline and subvolid $subvolid_cmdline was not found to be mounted, or it is not a BTRFS device."
    fi
    if [[ -z $ssh ]]; then
        printf "Select a mounted BTRFS device on your local machine to backup to.\n"
    else
        printf "Select a mounted BTRFS device on %s to backup to.\n" "$remote"
    fi
    while [[ $disk -lt 0 || $disk -gt $i ]]; do
        for x in "${!TARGETS_ARRAY[@]}"; do
            printf "%4s) %s (uuid=%s, subvolid=%s)\n" "$((x+1))" "${TARGETS_ARRAY[$x]}" "${UUIDS_ARRAY[$x]}" "${SUBVOLIDS_ARRAY[$x]}"
        done
        printf "%4s) Exit\n" "0"
        read -r -p "Enter a number: " disk
        if ! [[ $disk == ?(-)+([0-9]) ]]; then
            printf "\nNo disk selected. Select a disk to continue.\n"
            disk=-1
        fi
    done
    if [[ $disk == 0 ]]; then
        exit 0
    fi
    disk=$(($disk-1))
fi

selected_subvolid="${SUBVOLIDS_ARRAY[$((disk))]}"
selected_uuid="${UUIDS_ARRAY[$((disk))]}"
selected_mnt="${TARGETS_ARRAY[$((disk))]}"
printf "\nYou selected the disk with UUID %s, subovolid=%s.\n" "$selected_uuid" "$selected_subvolid" | tee $PIPE
if [[ -z $ssh ]]; then
    printf "The disk is mounted at %s.\n" "$selected_mnt" | tee $PIPE
else
    printf "The disk is mounted at %s:%s.\n" "$remote" "$selected_mnt" | tee $PIPE
fi

source $SNAPPER_CONFIG

selected_configs=${selected_configs:-$SNAPPER_CONFIGS}

declare -a BACKUPDIRS_ARRAY
declare -a MYBACKUPDIR_ARRAY
declare -a OLD_NUM_ARRAY
declare -a OLD_SNAP_ARRAY
declare -a NEW_NUM_ARRAY
declare -a NEW_SNAP_ARRAY
declare -a NEW_INFO_ARRAY
declare -a BACKUPLOC_ARRAY
declare -a CONT_BACKUP_ARRAY

printf "\nInitial configuration...\n" | tee $PIPE

# Initial configuration of where backup directories are
i=0
for x in $selected_configs; do

    if [[ "$(snapper -c $x list -t single | awk '/'"subvolid=$selected_subvolid, uuid=$selected_uuid"'/ {cnt++} END {print cnt}')" -gt 1 ]]; then
        error "More than one snapper entry found with UUID $selected_uuid subvolid $selected_subvolid for configuration $x. Skipping configuration $x."
        continue
    fi

    if [[ "$(snapper -c $x list -t single | awk '/'$progname' backup in progress/ {cnt++} END {print cnt}')" -gt 0 ]]; then
        printf "\nNOTE: Previous failed %s backup snapshots found for '%s'.\n" "$progname" "$x" | tee $PIPE
        read -r -p "Delete failed backup snapshots [y/N]? " delete_failed
        while [[ -n "$delete_failed" && "$delete_failed" != [Yy]"es" &&
            "$delete_failed" != [Yy] && "$delete_failed" != [Nn]"o" &&
            "$delete_failed" != [Nn] ]]; do
            read -r -p "Delete failed backup snapshots [y/N]? " delete_failed
            if [[ -n "$delete_failed" && "$delete_failed" != [Yy]"es" &&
            "$delete_failed" != [Yy] && "$delete_failed" != [Nn]"o" &&
            "$delete_failed" != [Nn] ]]; then
                printf "Select 'y' or 'N'.\n"
            fi
        done
        if [[ "$delete_failed" == [Yy]"es" || "$delete_failed" == [Yy] ]]; then
            snapper -c $x delete $(snapper -c $x list | awk '/'$progname' backup in progress/ {print $3}')
        fi
    fi

    SNAP_SYNC_EXCLUDE=no

    if [[ -f "/etc/snapper/configs/$x" ]]; then
        source /etc/snapper/configs/$x
    else
        die "Selected snapper configuration $x does not exist."
    fi

    if [[ $SNAP_SYNC_EXCLUDE == "yes" ]]; then
        continue
    fi

    printf "\n"

    old_num=$(snapper -c "$x" list -t single | awk '/'"subvolid=$selected_subvolid, uuid=$selected_uuid"'/ {print $1}')
    old_snap=$SUBVOLUME/.snapshots/$old_num/snapshot

    OLD_NUM_ARRAY[$i]=$old_num
    OLD_SNAP_ARRAY[$i]=$old_snap

    if [[ -z "$old_num" ]]; then
        printf "No backups have been performed for '%s' on this disk.\n" "$x"
        read -r -p "Enter name of subvolume to store backups, relative to $selected_mnt (to be created if not existing): " mybackupdir
        printf "This will be the initial backup for snapper configuration '%s' to this disk. This could take awhile.\n" "$x"
        BACKUPDIR="$selected_mnt/$mybackupdir"
        $ssh subvolume create "$BACKUPDIR"
    else
        mybackupdir=$(snapper -c "$x" list -t single | awk -F"|" '/'"subvolid=$selected_subvolid, uuid=$selected_uuid"'/ {print $5}' | awk -F "," '/backupdir/ {print $1}' | awk -F"=" '{print $2}')
        BACKUPDIR="$selected_mnt/$mybackupdir"
        $ssh test -d $BACKUPDIR || die "%s is not a directory on %s.\n" "$BACKUPDIR" "$selected_uuid"
    fi
    BACKUPDIRS_ARRAY[$i]="$BACKUPDIR"
    MYBACKUPDIR_ARRAY[$i]="$mybackupdir"

    printf "Creating new snapshot for %s...\n" "$x" | tee $PIPE
    new_num=$(snapper -c "$x" create --print-number -d "$progname backup in progress")
    new_snap=$SUBVOLUME/.snapshots/$new_num/snapshot
    new_info=$SUBVOLUME/.snapshots/$new_num/info.xml
    sync
    backup_location=$BACKUPDIR/$x/$new_num/
    if [[ -z $ssh ]]; then
        printf "Will backup %s to %s\n" "$new_snap" "$backup_location/snapshot" | tee $PIPE
    else
        printf "Will backup %s to %s\n" "$new_snap" "$remote":"$backup_location/snapshot" | tee $PIPE
    fi

    NEW_NUM_ARRAY[$i]="$new_num"
    NEW_SNAP_ARRAY[$i]="$new_snap"
    NEW_INFO_ARRAY[$i]="$new_info"
    BACKUPLOC_ARRAY[$i]="$backup_location"

    cont_backup="K"
    CONT_BACKUP_ARRAY[$i]="yes"
    if [[ $noconfirm == "yes" ]]; then
        cont_backup="yes"
    else
        while [[ -n "$cont_backup" && "$cont_backup" != [Yy]"es" &&
            "$cont_backup" != [Yy] && "$cont_backup" != [Nn]"o" &&
            "$cont_backup" != [Nn] ]]; do
            read -r -p "Continue with backup [Y/n]? " cont_backup
            if [[ -n "$cont_backup" && "$cont_backup" != [Yy]"es" &&
            "$cont_backup" != [Yy] && "$cont_backup" != [Nn]"o" &&
            "$cont_backup" != [Nn] ]]; then
                printf "Select 'Y' or 'n'.\n"
            fi
        done
    fi

    if [[ "$cont_backup" != [Yy]"es" && "$cont_backup" != [Yy] && -n "$cont_backup" ]]; then
        CONT_BACKUP_ARRAY[$i]="no"
        printf "Aborting backup for this configuration.\n"
        snapper -c $x delete $new_num
    fi

    i=$(($i+1))

done

# Actual backing up
printf "\nPerforming backups...\n" | tee $PIPE
i=-1
for x in $selected_configs; do

    i=$(($i+1))

    SNAP_SYNC_EXCLUDE=no

    if [[ -f "/etc/snapper/configs/$x" ]]; then
        source /etc/snapper/configs/$x
    else
        die "Selected snapper configuration $x does not exist."
    fi

    cont_backup=${CONT_BACKUP_ARRAY[$i]}
    if [[ $cont_backup == "no" || $SNAP_SYNC_EXCLUDE == "yes" ]]; then
        notify_info "Backup in progress" "NOTE: Skipping $x configuration."
        continue
    fi

    notify_info "Backup in progress" "Backing up $x configuration."

    printf "\n"

    old_num="${OLD_NUM_ARRAY[$i]}"
    old_snap="${OLD_SNAP_ARRAY[$i]}"
    BACKUPDIR="${BACKUPDIRS_ARRAY[$i]}"
    mybackupdir="${MYBACKUPDIR_ARRAY[$i]}"
    new_num="${NEW_NUM_ARRAY[$i]}"
    new_snap="${NEW_SNAP_ARRAY[$i]}"
    new_info="${NEW_INFO_ARRAY[$i]}"
    backup_location="${BACKUPLOC_ARRAY[$i]}"

    $ssh mkdir -p $backup_location

    if [[ -z "$old_num" ]]; then
        printf "Sending first snapshot for %s...\n" "$x" | tee $PIPE
        btrfs send "$new_snap" | $ssh btrfs receive "$backup_location" &>/dev/null

    else

        printf "Sending incremental snapshot for %s...\n" "$x" | tee $PIPE
        # Sends the difference between the new snapshot and old snapshot to the
        # backup location. Using the -c flag instead of -p tells it that there
        # is an identical subvolume to the old snapshot at the receiving
        # location where it can get its data. This helps speed up the transfer.
        btrfs send -c "$old_snap" "$new_snap" | $ssh btrfs receive "$backup_location"
        printf "Modifying data for old snapshot for %s...\n" "$x" | tee $PIPE
        snapper -v -c "$x" modify -d "old snap-sync snapshot (you may remove)" -u "backupdir=,subvolid=,uuid=" -c "number" "$old_num"
    fi

    if [[ -z $ssh ]]; then
        cp "$new_info" "$backup_location"
    else
        rsync -avzq "$new_info" "$remote":"$backup_location"
    fi

    # It's important not to change this userdata in the snapshots, since that's how
    # we find the previous one.

    userdata="backupdir=$mybackupdir, subvolid=$selected_subvolid, uuid=$selected_uuid"

    # Tag new snapshot as the latest
    printf "Tagging new snapshot as latest backup for %s...\n" "$x" | tee $PIPE
    snapper -v -c "$x" modify -d "$description" -u "$userdata" "$new_num"

    printf "Backup complete for configuration %s.\n" "$x" > $PIPE

done

printf "\nDone!\n" | tee $PIPE
exec 3>&-

if [[ "$uuid_cmdline" != "none" ]]; then
    notify_info "Finished" "Backups to $uuid_cmdline complete!"
else
    notify_info "Finished" "Backups complete!"
fi
