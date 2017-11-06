# snap-sync

## About

`snap-sync` is implemented as a posix shell script.
It takes advantage of the specific functionality of a btrfs filesystem and
makes it possible to backup date while sending incremental snapshots to another
drive. 

Plug in and mount any btrfs-formatted device you want your system to be
backed up to (like a USB drive).  When you run the `snap-sync` you will be prompted
to select a mounted btrfs device, or you can optionally select the disk using
its UUID or mountpoint on the command line.

Per default, `snap-sync` iterates through all snapper configurations found on
your source system. If you prefere, to just run on a specific configuration
you can select it using the `-c` flag. For each selected configuration it will
use snappers functionaltiy to create and manage a new local snapshot.
If you have never synced to the specified device, you will be prompted to
optionaly select a directory on the target device. Before the actual sync to 
your target disk take place, the final location will be presented where the backed
up snapshot be saved.
After an initial first sync, only the changes since the last backup have to be sent.

## Requirements

`snap-sync`relies on external tools to achieve its goal.
At runtime their availablity is checked. Following tools are are used:

- snapper
- awk
- sed
- notify-send

## Installation

    # make install

If your system uses a non-default location for the snapper
configuration file, specify it on the command line with
`SNAPPER_CONFIG`. For example, for
Arch Linux use:

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
     -l, --TARGET <target>    Specify the mountpoint of the BTRFS subvolume to back up to.
         --remote <address>   Send the snapshot backup to a remote machine. The snapshot will be sent via ssh. You
                              should specify the remote machine's hostname or ip address. The 'root' user must be
                              permitted to login on the remote machine.
         --dry-run            perform a trial run with no changes made.
     -v, --verbose            Be more verbose on what's going on.

## First run

When you run `snap-sync` you will be prompted to choose a disk to back up to.
The first time you run `snap-sync` for a particular disk (new UUID/SUBVOLID) you will be
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

### Dry-run with verbose output for snapper config 'home'

    # snap-sync --verbose --dry-run --config root

    select a mounted BTRFS device on your local machine to backup to.
       0) 62a45211-9197-4a5f-aeaf-0ab803a42c32 /data2 (subvolid=261,subvol=/data2)
       1) 62a45211-9197-4a5f-aeaf-0ab803a42c32 /home (subvolid=258,subvol=/home)
       2) 62a45211-9197-4a5f-aeaf-0ab803a42c32 /data2/.snapshots (subvolid=262,subvol=/@snapshots-data2)
       3) 62a45211-9197-4a5f-aeaf-0ab803a42c32 /home/.snapshots (subvolid=259,subvol=/@snapshots-home)
       4) 2ba04452-74aa-44df-b1c7-74e0a70c6543 /var/lib/machines (subvolid=260,subvol=/machines)
       5) 2ba04452-74aa-44df-b1c7-74e0a70c6543 /var/lib/libvirt (subvolid=261,subvol=/libvirt)
       6) 2ba04452-74aa-44df-b1c7-74e0a70c6543 /data (subvolid=257,subvol=/data)
       7) 2ba04452-74aa-44df-b1c7-74e0a70c6543 /var/lib/machines/.snapshots (subvolid=2121,subvol=/@snapshots-machines)
       8) 2ba04452-74aa-44df-b1c7-74e0a70c6543 /data/.snapshots (subvolid=258,subvol=/@snapshots-data)
       9) 7360922b-c916-4d9f-a670-67fe0b91143c /run/media/wes/backup (subvolid=151,subvol=/@backups)
       x) Exit

    Selected Subvol-ID=151: /run/media/wes/backup on 7360922b-c916-4d9f-a670-67fe0b91143c

    You selected the disk with UUID 7360922b-c916-4d9f-a670-67fe0b91143c
    The disk is mounted at /run/media/wes/backup.

    Verify configuration...

    Last syncronized Snapshot-ID for 'home':
    Last syncronized Snapshot-Path for 'home': /home/.snapshots//snapshot
    No backups have been performed for snapper config 'root' on this disk.
    Enter name of directory to store backups, relative to /run/media/wes/backup (to be created if not existing): acer-c720
	This will be the initial backup for snapper configuration 'root' to this disk. This could take awhile.
	Backup-Path: /data/.snapshots/acer-c720/
	Creating new snapshot with snapper config 'home' ...
	Will backup /home/.snapshots/233/snapshot to /run/media/wes/backup/acer-c720/home/.snapshots/233/snapshot
	Continue with backup [Y/n]? y

	Performing backups...
	would run: verify_snapper_structure /run/media/wes/backup/acer-c720 root .snapshots 233
    Sending first snapshot for snapper config 'home'...
    btrfs send //.snapshots/233/snapshot |  btrfs receive /run/media/wes/backup/acer-c720/home/.snapshots/233
    would run: btrfs send //.snapshots/233/snapshot |  btrfs receive /run/media/wes/backup/acer-c720/home/.snapshots/233
    would run: cp /home/.snapshots/233/info.xml /run/media/wes/backup/acer-c720/home/.snapshots/233
	Tagging new snapshot as latest backup for 'home' ...
    would run:  snapper -v -c home modify -d latest incremental backup -u backupdir=acer-c720, uuid=7360922b-c916-4d9f-a670-67fe0b91143c, subvolid=151 233

    Done!

The related snapshots from this on the local machine are for `home`:

    single | 233 |       | Sat 01 Oct 2016 07:48:40 AM CDT | root |          | latest incremental backup | backupdir=acer-c720, uuid=7360922b-c916-4d9f-a670-67fe0b91143c, subvolid=151

As you can see the userdata column for snapper is used to keep track of these
snapshots. In a next run, `snap-sync` will reflect the availability of a previous
snapshot and only need to send the differences.

### Dry-run with given Target for snapper config 'home', no confirmations

This is essentially what the systemd service does.

    # snap-sync --UUID 7360922b-c916-4d9f-a670-67fe0b91143c --noconfirm
    snap-sync Starting backups to '/run/media/wes/backup' ...
    Selecting a mounted BTRFS device for backups on your local machine.

    You selected the disk with UUID 7360922b-c916-4d9f-a670-67fe0b91143c.
    The disk is mounted at /run/media/wes/backup.

    Verify configuration...

    No backups have been performed for snapper config 'home' on target disk.
    The initial backup could take awhile.
    dryrun: Creating new snapshot with snapper config 'home' ...
    Will backup to /run/media/wes/backup/home/.snapshots/<new-id>/snapshot

    Performing backups...
    snap-sync Backing up data for configuration 'home'.

    dryrun: verify_snapper_structure /run/media/wes/backup home .snapshots
    Sending first snapshot for snapper config 'home'...
    dryrun: btrfs send  |  btrfs receive /run/media/wes/backup/home/.snapshots/
    dryrun: cp  /run/media/wes/backup/home/.snapshots/
    Tagging new snapshot as latest backup for 'home' ...
    dryrun: snapper -v -c home modify -d latest incremental backup -u backupdir=, uuid=7360922b-c916-4d9f-a670-67fe0b91143c, subvolid=151
    snap-sync Backups complete!

## Contributing

Help wanted! Feel free to fork and issue a pull request to add features or
tackle an open issue.
