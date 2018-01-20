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

If your system uses a non-default location for the snapper
configuration file, specify it on the command line with
`SNAPPER_CONFIG`. For example, for Arch Linux use:

    # make SNAPPER_CONFIG=/etc/conf.d/snapper install

The package is also available in the
[AUR](https://aur.archlinux.org/packages/snap-sync/).

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
     -s, --subvolid <subvlid> Specify the subvolume id of the mounted BTRFS subvolume to back up to. Defaults to 5.
     -r, --remote <address>   Send the snapshot backup to a remote machine. The snapshot will be sent via ssh. You 
                              should specify the remote machine's hostname or ip address. The 'root' user must be 
                              permitted to login on the remote machine.
     -p, --port <port>        The remote port.

## First run

When you run `snap-sync` you will be prompted to choose a disk to back up to.
The first time you run `snap-sync` for a particular disk (new UUID) you will be
prompted to choose a backup location on that disk. If the directory you specify
does not exist, it will be created.

## Example command line usage

### No arguments

    # snap-sync

    Select a mounted BTRFS device on your local machine to backup to.
       1) /mnt (uuid=7360922b-c916-4d9f-a670-67fe0b91143c, subvolid=5)
       0) Exit
    Enter a number: 1

    You selected the disk with UUID 7360922b-c916-4d9f-a670-67fe0b91143c, subovolid=5.
    The disk is mounted at /mnt.

    Initial configuration...

    Creating new snapshot for home...
    Will backup /home/.snapshots/4196/snapshot to /mnt/acer-c720/home/4196//snapshot
    Continue with backup [Y/n]?

    Creating new snapshot for root...
    Will backup //.snapshots/8455/snapshot to /mnt/acer-c720/root/8455//snapshot
    Continue with backup [Y/n]?

    Performing backups...

    Sending incremental snapshot for home...
    At subvol /home/.snapshots/4196/snapshot
    At snapshot snapshot
    Modifying data for old snapshot for home...
    Tagging new snapshot as latest backup for home...

    Sending incremental snapshot for root...
    At subvol //.snapshots/8455/snapshot
    At snapshot snapshot
    Modifying data for old snapshot for root...
    Tagging new snapshot as latest backup for root...

    Done!

The related snapshots from this on the local machine are for `home`:

    single | 4196 |       | Sat 11 Nov 2017 01:37:44 PM EST | root |          | latest incremental backup | backupdir=acer-c720, subvolid=5, uuid=7360922b-c916-4d9f-a670-67fe0b91143c

and for `root`:

    single | 8455 |       | Sat 11 Nov 2017 01:37:46 PM EST | root |          | latest incremental backup | backupdir=acer-c720, subvolid=5, uuid=7360922b-c916-4d9f-a670-67fe0b91143c

As you can see the userdata column for snapper is used to keep track of these
snapshots for the next time the script is run so that only the changes will need
to be sent.

### With UUID and subvolid specified and no confirmations

    # snap-sync --UUID 7360922b-c916-4d9f-a670-67fe0b91143c --subvolid 5 --noconfirm

    You selected the disk with UUID 7360922b-c916-4d9f-a670-67fe0b91143c, subovolid=5.
    The disk is mounted at /mnt.

    Initial configuration...

    Creating new snapshot for home...
    Will backup /home/.snapshots/4197/snapshot to /mnt/acer-c720/home/4197//snapshot

    Creating new snapshot for root...
    Will backup //.snapshots/8456/snapshot to /mnt/acer-c720/root/8456//snapshot

    Performing backups...

    Sending incremental snapshot for home...
    At subvol /home/.snapshots/4197/snapshot
    At snapshot snapshot
    Modifying data for old snapshot for home...
    Tagging new snapshot as latest backup for home...

    Sending incremental snapshot for root...
    At subvol //.snapshots/8456/snapshot
    At snapshot snapshot
    Modifying data for old snapshot for root...
    Tagging new snapshot as latest backup for root...

    Done!

## systemd example

## service

    [Unit]
    Description=Run snap-sync backup 

    [Install]
    WantedBy=multi-user.target

    [Service]
    Type=simple
    ExecStart=/usr/bin/snap-sync --UUID 7360922b-c916-4d9f-a670-67fe0b91143c --subvolid 5 --noconfirm

## timer

    [Unit]
    Description=Run snap-sync weekly

    [Timer]
    OnCalendar=weekly
    AccuracySec=12h
    Persistent=true

    [Install]
    WantedBy=timers.target

## Contributing

Help wanted! Feel free to fork and issue a pull request to add features or
tackle an open issue.

## Related projects

See @rzerres's [fork](https://github.com/rzerres/snap-sync) which has several enhancments.
