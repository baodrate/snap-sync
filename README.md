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

On Arch Linux install via pacman. Alternatively download the latest release and o:

    # make install

If your system uses a non-default location for the snapper
configuration file, specify it on the command line with
`SNAPPER_CONFIG`. For example, for Arch Linux use:

    # make SNAPPER_CONFIG=/etc/conf.d/snapper install

## Options

Run `snap-sync -h` to see available options.

## First run

When you run `snap-sync` you will be prompted to choose a disk to back up to.
The first time you run `snap-sync` for a particular disk (new UUID) you will be
prompted to choose a backup location on that disk. If the directory you specify
does not exist, it will be created.

## Example command line usage

### No arguments

    # snap-sync

### With UUID and subvolid specified and no confirmations

    # snap-sync --UUID 7360922b-c916-4d9f-a670-67fe0b91143c --subvolid 5 --noconfirm

## Viewing snap-sync snapshots

Simply use `snapper` to view the snapshots for a subvolume you have backed up. A
snapshots with the description `Latest incremental backup` is kept on our local machine
so that the next time `snap-sync` runs it will only transfer the difference between it
and a new snapshot. Don't manually delete that snapshot unless you want to do an
entirely new backup, transferring all of the data again.

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

## License

    snap-sync
    Copyright (C) 2016-2019, Wes Barnett

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

See `LICENSE` for more information.

## Related projects

See @rzerres's [fork](https://github.com/rzerres/snap-sync) which has several enhancments.
