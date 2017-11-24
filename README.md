<!-- snap-sync README.md -->
<!-- version: 0.5.1 -->

# snap-sync

## About

`snap-sync` is implemented as a posix shell script.
It takes advantage of the specific functionality of a btrfs file system and
makes it possible to backup data while sending incremental snapshots to another
drive. It's fine to store to dives on a remote host (using ssh).

Plug in and mount any btrfs-formatted device you want your system to be
backed up to (eg. local USB drive, remote RAID drives).

`snap-sync` will support interactive an time scheduled backup runs.

* An interactive run will request you to select a mounted btrfs device.
You can pre-select the target drive via [command line options](https://github.com/wesbarnett/snap-sync#options).
Either use the UUID, the SUBVOLID or it's TARGET (read 'mount point').

* A scheduled run will take all needed parameters from config options.

For a backup run, `snap-sync` will iterate through all defined snapper configurations
found on your source system. If you prefer to just run on a specific configuration,
you can select this using the 'config' option `-c`. For each selected configuration
it will use snapper to create an appropriate local snapshot.

## Requirements

`snap-sync`relies on external tools to achieve its goal.
At run-time their availability is checked. Following tools are are used:

- snapper
- awk
- sed
- notify-send

## Installation

    # make install

If your system uses a non-default location for the snapper
configuration file, specify it on the command line with
`SNAPPER_CONFIG`. For example, for Arch Linux use:

    # make SNAPPER_CONFIG=/etc/conf.d/snapper install

The local snapper configuration will be extended to make use
of a new template 'snap-sync'.

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
     -u, --uuid <UUID>        Specify the UUID of the mounted BTRFS subvolume to back up to. Otherwise will prompt.
         --UUID <UUID>        If multiple mount points are found with the same UUID, will prompt user.
     -s, --subvolid <subvlid> Specify the subvolume id of the mounted BTRFS subvolume to back up to. Defaults to 5.
         --SUBVOLID
     -t, --target <target>    Specify the mountpoint of the BTRFS subvolume to back up to.
	     --TARGET <target>
         --remote <address>   Send the snapshot backup to a remote machine. The snapshot will be sent via ssh. You
                              should specify the remote machine's hostname or ip address. The 'root' user must be
                              permitted to login on the remote machine.
         --dry-run            perform a trial run with no changes made.
     -v, --verbose            Be more verbose on what's going on.

## First run

If you have never synced to the paticular target device (first run), `snap-sync`
will take care to create the necessary target file-structure to store the snapshot.
As an option you can prepend a backup-path.

Before the sync job is started, source and target locations will be presented.
You have to confirm any further operation, or use defaults (option: noconfirm).

## Example command line usage

### Snap-sync to local target

#### Default: no selections, run for all snapper configs

    # snap-sync

#### Default: Select two configs, the backupdir and verbose output

    # snap-sync --verbose --config root --config data2 --backupdir=toshiba_r700

#### Dry-run: Select config, select Target, as batchjob (--noconfirm)

    # snap-sync  -c root -s 265 --noconfirm --dry-run


### Snap-sync to remote host

`snap-sync` will rely on ssh access to the target host. For batch usage make sure, that your
public key is accepted for remote login as user 'root'. You may have to adapt /root/.ssh/authorized_keys
on the target host.

On your target host, you should also verify the availability of a snap-sync config-template for snapper.
A template `snap-sync` is included in the package for your convenience.

#### Dryrun: Select remote host <ip/fqdn>, interactive, run for all configs

    snap-sync --dry-run --remote 172.16.0.3
	Selecting a mounted BTRFS device for backups on 172.16.0.3.
	  0) / (uuid=5af3413e-59ea-4862-8cff-304afe25420f,subvolid=257,subvol=/root)
	  1) /.snapshots (uuid=5af3413e-59ea-4862-8cff-304afe25420f,subvolid=258,subvol=/@snapshots-root)
	  2) /data2 (uuid=62a45211-9197-4a5f-aeaf-0ab803a42c32,subvolid=261,subvol=/data2)
	  3) /home (uuid=62a45211-9197-4a5f-aeaf-0ab803a42c32,subvolid=258,subvol=/home)
	  4) /data2/.snapshots (uuid=62a45211-9197-4a5f-aeaf-0ab803a42c32,subvolid=262,subvol=/@snapshots-data2)
	  5) /home/.snapshots (uuid=62a45211-9197-4a5f-aeaf-0ab803a42c32,subvolid=259,subvol=/@snapshots-home)
	  6) /var/lib/machines (uuid=2ba04452-74aa-44df-b1c7-74e0a70c6543,subvolid=260,subvol=/machines)
	  7) /var/lib/libvirt (uuid=2ba04452-74aa-44df-b1c7-74e0a70c6543,subvolid=261,subvol=/libvirt)
	  8) /data (uuid=2ba04452-74aa-44df-b1c7-74e0a70c6543,subvolid=257,subvol=/data)
	  9) /var/lib/machines/.snapshots (uuid=2ba04452-74aa-44df-b1c7-74e0a70c6543,subvolid=2121,subvol=/@snapshots-machines)
	 10) /data/.snapshots (uuid=2ba04452-74aa-44df-b1c7-74e0a70c6543,subvolid=258,subvol=/@snapshots-data)
	 11) /var/lib/snap-sync (uuid=753eba7a-41ce-49e0-b2e3-24ee07811efd,subvolid=420,subvol=/snap-sync)
	  x) Exit
    Enter a number: 11


### Dry-run with given Target for snapper config 'home', no confirmations

#### Sync: Select config 'data2', remote host <ip/fqdn>, target '/data', as batchjob (--noconfirm)

    # snap-sync --config data2 --remote 172.16.0.3 --target /data --noconfirm

## systemd example

### service

    [Unit]
    Description=Run snap-sync backup

    [Install]
    WantedBy=multi-user.target

    [Service]
    Type=simple
    ExecStart=/usr/bin/snap-sync --UUID 7360922b-c916-4d9f-a670-67fe0b91143c --subvolid 5 --noconfirm

### timer

    [Unit]
    Description=Run snap-sync weekly

    [Timer]
    OnCalendar=weekly
    AccuracySec=12h
    Persistent=true

    [Install]
    WantedBy=timers.target

## snapper template

	###
	# template for snap-sync handling
	###

	# subvolume to snapshot
	SUBVOLUME="/var/lib/snap-sync"

	# filesystem type
	FSTYPE="btrfs"

	# users and groups allowed to work with config
	ALLOW_USERS=""
	ALLOW_GROUPS="adm"

	# sync users and groups from ALLOW_USERS and ALLOW_GROUPS to .snapshots
	# directory
	SYNC_ACL="yes"

	# start comparing pre- and post-snapshot in background after creating
	# post-snapshot
	BACKGROUND_COMPARISON="yes"

	# run daily number cleanup
	NUMBER_CLEANUP="no"

	# limit for number cleanup
	NUMBER_MIN_AGE="1800"
	NUMBER_LIMIT="10"
	NUMBER_LIMIT_IMPORTANT="2"

	# use systemd.timer for timeline
	TIMELINE_CREATE="no"

	# use systemd.timer for cleanup
	TIMELINE_CLEANUP="no"

    # snap-sync as timer unit
    SNAP_SYNC_EXCLUDE="yes"

## Contributing

Help wanted! Feel free to fork and issue a pull request to add features or
tackle an open issue.

## License

<!-- License source -->
[Logo-CC_BY]: https://i.creativecommons.org/l/by/4.0/88x31.png "Creative Common Logo"
[License-CC_BY]: https://creativecommons.org/licenses/by/4.0/legalcode "Creative Common License"

This work is licensed under a [Creative Common License 4.0][License-CC_BY]

![Creative Common Logo][Logo-CC_BY]

© 2016, 2017 James W. Barnett, Ralf Zerres
