# snap-sync

## About

This bash script sends incremental snapshots to another drive for backing up
data. Plug in and mount any btrfs-formatted device you want your system to be
backed up to (like a USB drive).  When you run the script you will be prompted
to select a mounted btrfs device, or you can optionally select the disk using
its UUID on the command line.

The script iterates through all snapper configurations by default (this can be
changed using the `-c` flag). For each configuration it creates a new local
snapshot. If you have never synced to the specified device you will be prompted
to enter a directory on the device where the backup snapshots will go.
Additionally you are shown the location of the backed up snapshot. If you have
performed a backup to this device before, only the changes since the last backup
have to be sent.

## Requirements

snapper is required.

## Installation

    # make install

The package is available in the [AUR](https://aur.archlinux.org/packages/snap-sync/).

## Options

    Usage: snap-sync [options]

    Options:
     -d, --description <desc> Change the snapper description. Default: "latest incremental backup"
     -c, --config <config>    Specify the snapper configuration to use. Otherwise will perform for each snapper
                              configuration. Can list multiple configurations within quotes, space-separated
                              (e.g. -c "root home").
     -n, --noconfirm          Do not ask for confirmation for each configuration. Will still prompt for backup
                              directory name on first backup
     -u, --UUID <UUID>        Specify the UUID of the mounted BTRFS subvolume to back up to. Otherwise will prompt.
                              If multiple mount points are found with the same UUID, will prompt user.
     --remote <address>       Send the snapshot backup to a remote machine. The snapshot will be sent via ssh. You
                              should specify the remote machine's hostname or ip address. The 'root' user must be
                              permitted to login on the remote machine.

## First run

When you run `snap-sync` you will be prompted to choose a disk to back up to.
The first time you run `snap-sync` for a particular disk (new UUID) you will be
prompted to choose a backup location on that disk. If the directory you specify
does not exist, it will be created.

## Systemd unit and timer

A systemd unit and timer are included. These are instantiated units. You need to
specify the UUID of the disk to back up to in the `systemctl` call. Note, once
again, the disk **must** be mounted, and it **must** only be mounted in one
place. Example:

    # systemctl start snap-sync@7360922b-c916-4d9f-a670-67fe0b91143c

The timer included is weekly. Edit both files to your taste.

You can exclude a configuration from backup by setting `SNAP_SYNC_EXCLUDE=yes`
in your snapper configuration file. Additionally you should run snap-sync at
least once for a new disk without using the service so you can be prompted for
the backup location.

## Example command line usage

### No arguments

    # snap-sync

    Select a mounted BTRFS device to backup to.
    1) 43cedfb6-8775-43be-8abc-ee63bb92e10e (/)
    2) 43cedfb6-8775-43be-8abc-ee63bb92e10e (/.snapshots)
    3) 43cedfb6-8775-43be-8abc-ee63bb92e10e (/home)
    4) 7360922b-c916-4d9f-a670-67fe0b91143c (/run/media/wes/backup)
    0) Exit
    Enter a number: 4

    You selected the disk with UUID 7360922b-c916-4d9f-a670-67fe0b91143c.
    The disk is mounted at /run/media/wes/backup.

    Will backup /home/.snapshots/1097/snapshot to /run/media/wes/backup/acer-c720/home/1097//snapshot
    Continue with backup [Y/n]? y
    At subvol /home/.snapshots/1097/snapshot

    Will backup //.snapshots/2288/snapshot to /run/media/wes/backup/acer-c720/root/2288//snapshot
    Continue with backup [Y/n]? y
    At subvol //.snapshots/2288/snapshot

    Done!

The related snapshots from this on the local machine are for `home`:

    single | 1097 |       | Sat 01 Oct 2016 07:48:40 AM CDT | root |          | latest incremental backup | backupdir=acer-c720, uuid=7360922b-c916-4d9f-a670-67fe0b91143c

and for `root`:

    single | 2288 |       | Sat 01 Oct 2016 07:50:56 AM CDT | root |          | latest incremental backup | backupdir=acer-c720, uuid=7360922b-c916-4d9f-a670-67fe0b91143c

As you can see the userdata column for snapper is used to keep track of these
snapshots for the next time the script is run so that only the changes will need
to be sent.

### With UUID specified and no confirmations

This is essentially what the systemd service does.

    # snap-sync --UUID 7360922b-c916-4d9f-a670-67fe0b91143c --noconfirm
    You selected the disk with UUID 7360922b-c916-4d9f-a670-67fe0b91143c.
    The disk is mounted at /run/media/wes/backup.

    Will backup /home/.snapshots/1379/snapshot to /run/media/wes/backup/acer-c720/home/1379//snapshot
    At subvol /home/.snapshots/1379/snapshot

    Will backup //.snapshots/2782/snapshot to /run/media/wes/backup/acer-c720/root/2782//snapshot
    At subvol //.snapshots/2782/snapshot

    Done!

## Contributing

Help wanted! Feel free to fork and issue a pull request to add features or
tackle an open issue.
