#!/bin/bash

source btrfs.sh
source defaults.sh
source disk.sh
source internet.sh
source logger.sh
source mirrors.sh
source utils.sh

main_handleInternet() {
    log_debug "Internet connection check"
    internet_displayConnectionStatus
}

main_handleMirrors() {
    log_debug "Setting mirrors"
    mirrors_update $DEFAULT_COUNTRY $DEFAULT_MIRRORS_LOOKBACK_SYNC_TIME

    log_debug "Update packages"
    pacman -Syy
}

main_handleDisk() {
    #Partition the disk
    log_debug "Partioning the disk"
    disk_backupAndUpdateLayout $DEFAULT_DISK $DEFAULT_PARTITION_SCHEME_FILE

    #Apply file system to partitions
    log_debug "Appling filesystems to partions"
    disk_setPartitionsFileSystems $DEFAULT_DISK $DEFAULT_PARTITION_SCHEME_FILE

    #Setup btrfs subvolumes
    local -r btrfs_partition=$(disk_getDiskPartitionsWithSpecifiedFileSystem $DEFAULT_DISK "btrfs")
    log_debug "Setting up btrfs subvolumes"
    btrfs_setUpSubvolumes $btrfs_partition $DEFAULT_BTRFS_LAYOUT_FILE

    #TODO(Jacek): boot $ partiton workaround
    local -r boot_partition=$(disk_getDiskPartitonWithSpecifiedMountPointFromLayoutFile $DEFAULT_DISK $DEFAULT_PARTITION_SCHEME_FILE "/mnt/boot")
    mkdir /mnt/boot
    mount $boot_partition "/mnt/boot"
    local -r swap_partition=$(disk_getDiskPartitonWithSpecifiedMountPointFromLayoutFile $DEFAULT_DISK $DEFAULT_PARTITION_SCHEME_FILE "swap")
    swapon $swap_partition

    # #Add btrfs module to kernel
    # log_debug "Add btrfs module to kernel"

}

main_handleUtils() {
    log_debug "Installing base packages"
    utils_runPacstrap "linux"

    log_debug "Generate fstab"
    utils_runGenfstab
}

main_jumpChroot() {
    log_debug "Coping scripts before context change"
    cp "../JQArchI" "/mnt/JQArchI" -ra

    log_debug "Entering installation directory"
    arch-chroot /mnt ./JQArchI/main_chroot.sh
}

main_handleInternet
main_handleMirrors
main_handleDisk
main_handleUtils
main_jumpChroot
