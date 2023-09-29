#!/bin/bash

if [ -n "$BTRFS_SH_SOURCED" ]; then return; fi
BTRFS_SH_SOURCED=true

#######################################
# Gets line from BTRFS layout file.
#
# Globals:
#   None
# Arguments:
#   BTRFS layout file, a path to file that contains btrfs subvolume specification
# Outputs:
#   Writes lines to STDOUT, where each contains
#   subvolume name | mount point | mount options, i.e.:
#   @home, /mnt/home, noatime,compress=lzo,space_cache=v2
#######################################
__btrfs_getLineFromLayoutFile() {
    local -r layout_file=$1

    grep -o '^[^#]*' $layout_file | awk '{print $1 $2 $3}'
}

#######################################
# Gets subvolume's mount points from BTRFS layout file.
#
# Globals:
#   None
# Arguments:
#   BTRFS layout file, a path to file that contains btrfs subvolume specification
# Outputs:
#   Writes list of subvolume's mount points, a list of strings to STDOUT 
#######################################
__btrfs_getMountPointsFromLayoutFile() {
    local -r layout_file=$1

    local -r lines=($(__btrfs_getLineFromLayoutFile $layout_file))
    for line in "${lines[@]}"; do
        IFS=","
        line=($line)
        unset IFS

        echo ${line[1]}
    done
}

#######################################
# Gets subvolumes from BTRFS layout file.
#
# Globals:
#   None
# Arguments:
#   BTRFS layout file, a path to file that contains btrfs subvolume specification
# Outputs:
#   Writes list od subvolumes, a list of strings to STDOUT 
#######################################
__btrfs_getSubvolumesFromLayoutFile() {
    local -r layout_file=$1

    local -r lines=($(__btrfs_getLineFromLayoutFile $layout_file))
    for line in "${lines[@]}"; do
        IFS=","
        line=($line)
        unset IFS

        echo ${line[0]}
    done
}

#######################################
# Creates btrfs subvolume.
#
# Globals:
#   None
# Arguments:
#   Subvolume name, a string like "@home"
# Outputs:
#   None
#######################################
__btrfs_createSubvolume() {
    local -r subvolume=$1

    btrfs su cr "$subvolume" #1>/dev/null 2>/dev/null
}

#######################################
# Creates btrfs subvolumes as specified in BTRFS layout file.
#
# Globals:
#   None
# Arguments:
#   BTRFS layout file, a path to file that contains btrfs subvolume specification
#   Base mount point for btrfs partion, a string
# Outputs:
#   0 if all subvolumes has been created
#   1 if at least on subvolume creation failed
#######################################
__btrfs_createSubvolumes() {
    local -r layout_file=$1
    local -r base_mount_point=$2

    local -r subvolumes=($(__btrfs_getSubvolumesFromLayoutFile $layout_file))

    for subvolume in "${subvolumes[@]}"; do
        __btrfs_createSubvolume $base_mount_point$subvolume
        if [ $? -ne 0 ]; then
            return 1
        fi
    done
}

#######################################
# Creates mount points for subvolumes as specified in BTRFS layout file.
#
# Globals:
#   None
# Arguments:
#   BTRFS layout file, a path to file that contains btrfs subvolume specification
# Outputs:
#   None
#######################################
__btrfs_createMountPoints() {
    local -r layout_file=$1
    local -r mount_points=($(__btrfs_getMountPointsFromLayoutFile $layout_file))
    local -r mount_points_without_root=(${mount_points[@]:1})

    for mount_point in "${mount_points_without_root[@]}"; do
        mkdir "$mount_point"
    done
}

#######################################
# Mounts BTRFS subvolume.
#
# Globals:
#   None
# Arguments:
#   Subvolume, a string like "@home"
#   Mount point, a string like "/mnt/home"
#   Partition for current btrfs operations, a string like "/dev/nvme0n1p3"
#   Additional mount options, a string
# Outputs:
#   None
#######################################
__btrfs_mountSubvolume() {
    local -r subvolume=$1
    local -r mount_point=$2
    local -r btrfs_partiton=$3
    local -r options=$4

    mount -o $options$([ -n "$options" ] && echo ",")subvol=$subvolume $btrfs_partiton $mount_point
}

#######################################
# Mounts BTRFS subvolumes as specified in layout file.
#
# Globals:
#   None
# Arguments:
#   BTRFS layout file, a path to file that contains btrfs subvolume specification
#   Partition for current btrfs operations, a string like "/dev/nvme0n1p3"
# Outputs:
#   None
#######################################
__btrfs_mountSubvolumes() {
    local -r layout_file=$1
    local -r btrfs_partition=$2

    local -r lines=($(__btrfs_getLineFromLayoutFile $layout_file))

    for line in "${lines[@]}"
    do
        IFS=","
        line=($line)
        unset IFS

        local subvolume=${line[0]}
        local mount_point=${line[1]}
        local options=$(echo ${line[@]:2} | tr -s ' ' ',')

        __btrfs_mountSubvolume $subvolume $mount_point $btrfs_partition $options

        #create rest of mount_points after mounting root subvolume
        if [ "$subvolume" = "@" ]; then
            __btrfs_createMountPoints $layout_file
        fi
    done
}

############################################### API ###############################################

#######################################
# Sets up BTRFS subvolumes as specified in BTRFS layout file
#
# Globals:
#   None
# Arguments:
#   Partition for current btrfs operations, a string like "/dev/nvme0n1p3"
#   BTRFS layout file, a path to file that contains btrfs subvolume specification
# Outputs:
#   Writes log message with operation result to STDOUT
# Returns:
#   0 if subvolumes has been set up
#   1 if mounting btrfs partition failed
#   2 if creating subvolumes failed
#   3 if unmouting btrfs partition failed
#   4 if remounting subvolumes failed
#######################################
btrfs_setUpSubvolumes() {
    local -r btrfs_partition=$1
    local -r base_mount_point="/mnt"

    #Mount btrfs partion to create subvolumes
    mount $btrfs_partition $base_mount_point
    if [ $? -ne 0 ]; then
        log_error "Failed mounting btrfs target [$btrfs_partition] under [$base_mount_point] mount point"
        return 1
    fi

    local -r layout_file=$2

    #Create subvolumes
    __btrfs_createSubvolumes $layout_file $base_mount_point"/"
    if [ $? -ne 0 ]; then
        log_error "Failed creating subvolumes"
        return 2
    fi

    #Unmouting btrfs partition
    umount "$btrfs_partition"
    if [ $? -ne 0 ]; then
        log_error "Failed unmounting btrfs partition"
        return 3
    fi

    #Remount subvolumes
    __btrfs_mountSubvolumes $layout_file $btrfs_partition
    if [ $? -ne 0 ]; then
        log_error "Failed remounting btrfs subvolumes"
        return 4
    fi

    log_info "Succesfully set up all btrfs subvolumes"
}
