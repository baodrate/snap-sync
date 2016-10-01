# snap-sync

## About

This bash script sends incremental snapshots to another drive for backing up
data. Plug in and mountany btrfs-formatted device you want your system to be
backed up to (like a USB drive).  When you run the script you will be prompted
to select a mounted btrfs device.

The script iterates through all snapper configurations. For each configuration
it creates a new local snapshot. If you have never synced to the specified
device you will be prompted to enter a directory on the device where the backup
snapshots will go. Additionally you are show the location of the backed up
snapshot. If you have performed a backup to this device before, only the changes
since the last backup have to be sent.

snapper is required.

## Example output

    Selected a mounted BTRFS device to backup to.
    1) 43cedfb6-8775-43be-8abc-ee63bb92e10e (/)
    2) 43cedfb6-8775-43be-8abc-ee63bb92e10e (/.snapshots)
    3) 43cedfb6-8775-43be-8abc-ee63bb92e10e (/home)
    4) 7360922b-c916-4d9f-a670-67fe0b91143c (/run/media/wes/backup)
    0) Exit
    Enter a number: 4
    You selected the disk with UUID 7360922b-c916-4d9f-a670-67fe0b91143c.
    At 'home' configuration
    Backup location: /run/media/wes/backup/acer-c720/home/1097/
    Continue (y/n)? y
    At subvol /home/.snapshots/1097/snapshot
    At 'root' configuration
    Backup location: /run/media/wes/backup/acer-c720/root/2288/
    Continue (y/n)? y
    At subvol //.snapshots/2288/snapshot
    Done!
