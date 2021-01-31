# snap-sync

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

## Installation

### Arch Linux

Install the `snap-sync` package using pacman if using Arch Linux.

### Fedora

Install the `snap-sync` package from [this Copr] created by [@brndd].

### Manual

Download the latest release and signature from the [releases page], verify the download, and then
run `make install`. snapper is required.

If your system uses a non-default location for the snapper
configuration file, specify it on the command line with
`SNAPPER_CONFIG`. For example, for Arch Linux use

    make SNAPPER_CONFIG=/etc/conf.d/snapper install

Starting with release 0.6, the tarballs are signed with my key with fingerprint
`F7B28C61944FE30DABEEB0B01070BCC98C18BD66` ([public key]). Previous tarballs and commits
used a different key with fingerprint `8535CEF3F3C38EE69555BF67E4B5E45AA3B8C5C3`.

## Dependencies

### Mandatory dependencies:

The dependencies below are Arch Linux package names. Packages on other distros may use different names.

* bash
* btrfs-progs
* coreutils
* gawk
* grep
* snapper
* systemd
* util-linux
* which

### Optional dependencies:

* libnotify (for desktop notifications)
* openssh (for remote backups)
* pv (for progress bar during backup)
* rsync (for remote backups)
* sudo (for desktop notifications)

## Documentation

See `snap-sync(8)` after installation.

## Troubleshooting

After reviewing the man page, check the [issues page] and file a new issue if your
problem is not covered.

## Contributing

Help wanted! Feel free to fork and issue a pull request to add features or
tackle an open issue.

## Related projects

See [@rzerres's fork] which has several enhancments.

[this Copr]: https://copr.fedorainfracloud.org/coprs/peoinas/snap-sync/
[@brndd]: https://github.com/brndd
[releases page]: https://github.com/wesbarnett/snap-sync/releases
[public key]: https://barnett.science/public-key.asc
[issues page]: https://github.com/wesbarnett/snap-sync/issues
[@rzerres's fork]: https://github.com/rzerres/snap-sync
