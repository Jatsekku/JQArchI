#!/bin/bash

if [ -n "$DISK_SH_SOURCED" ]; then return; fi
DISK_SH_SOURCED=true

source logger.sh

#######################################
# Gets disks devices present in the system.
#
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Writes lines to STDOUT, where each contains
#   disk NAME TYPE(=disk) SIZE. i.e.:
#   sda     disk 14.5G
#   nvme0n1 disk 100G 
#######################################
__disk_getDisks() {
    lsblk -ln -o NAME,TYPE,SIZE | grep disk
}

#######################################
# Checks if disk is available in the system.
#
# Globals:
#   None
# Arguments:
#   Selected disk, a string like "/dev/nvme0n1"
# Outputs:
#   None
# Returns:
#   0 if disk is available, non-zero otherwise
#######################################
__disk_checkDiskAvailability() {
    local -r selected_disk=$1
    local -r selected_disk_base=$(basename $selected_disk)
    local -r available_disks=$(__disk_getDisks | awk '{print $1}')

    if  [[ !(${available_disks[*]} =~ "$selected_disk_base") ]]; then
        return 1
    fi
}

#######################################
# Gets partitions created on disk.
#
# Globals:
#   None
# Arguments:
#   Selected disk, a string like "/dev/nvme0n1"
# Outputs:
#   Writes list of partitions on disk, a list of string to STDOUT
#######################################
__disk_getDiskPartitions() {
    local -r selected_disk=$1

    lsblk -ln -o NAME,TYPE $selected_disk | grep part | awk {'print "/dev/" $1'}
}

#######################################
# Gets disks and partitions present in the system.
#
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Writes all disks and partitions available in the system, a list of strings to STDOUT
#######################################
__disk_getDiskAndPartitons() {
    lsblk -ln -o NAME,TYPE | grep -e part -e disk | awk {'print "/dev/" $1'}
}

#######################################
# Checks if disk or partition is available in the system.
#
# Globals:
#   None
# Arguments:
#   Selected target, a string like "/dev/nvme0n1" or "/dev/nvme0n1p3"
# Outputs:
#   None
# Returns:
#   0 if target is available, non-zero otherwise
#######################################
__disk_checkDiskOrPartitionAvailability() {
    local -r selected_target=$1
    local -r selected_target_base=$(basename $selected_disk)
    local -r available_targets=($(__disk_getDiskAndPartitons))

    if  [[ !(${available_targets[*]} =~ "$selected_target_base") ]]; then
        return 1
    fi
}

#######################################
# Gets file systems of partitions from layout file
#
# Function gets phrases specified between [] braces from layout file.
# Such a formating has been added to standard fsdisk input file
# in oreder to provide desired file system per each partition.
#
# Globals:
#   None
# Arguments:
#   Layout file, a path to file that contains instruction for sfdisk command
# Outputs:
#   Writes desired file systems of each partitions, a list of string to STDOUT
#######################################
__disk_getPartitionsFsFromLayoutFile() {
    local -r layout_file=$1

    grep -oP '\[([^]]*)\]' $layout_file | tr -d '[]'
}

#######################################
# Gets mount points of partitions from layout file
#
# Function gets phrases specified between {} braces from layout file.
# Such a formating has been added to standard fsdisk input file
# in oreder to provide desired mount point per each partition.
#
# Globals:
#   None
# Arguments:
#   Layout file, a path to file that contains instruction for sfdisk command
# Outputs:
#   Writes desired mount point of each partitions, a list of string to STDOUT
#######################################
__disk_getMountPointsFromLayoutFile() {
    local -r layout_file=$1

    grep -oP '\{([^]]*)\}' $layout_file | tr -d '{}'
}

#######################################
# Creates backup of layout for specified disk.
#
# Globals:
#   None
# Arguments:
#   Selected disk, a string like "/dev/nvme0n1"
#   Backup file, a path for file where backup should be written
# Outputs:
#   None
# Returns: 
#   0 if backup has been created
#   1 if selected disk is not available
#   2 if creating backup failed
#######################################
__disk_backupLayout() {
    local -r selected_disk=$1

    #Check disk availability
    __disk_checkDiskAvailability $selected_disk
    if [ $? -ne 0 ]; then
        return 1
    fi

    local -r backup_file=$2

    #Backup disk's layout
    sfdisk $selected_disk --dump > $backup_file"_tmp" 2>/dev/null

    #If backuping suceeded remove "_tmp" from file name
    local -r operation_result=$?
    if [ $operation_result -eq 0 ]; then
        mv $backup_file"_tmp" $backup_file
    #Remove file and return error code otherwise
    else
        rm $backup_file"_tmp"
        return 2
    fi
}

#######################################
# Create new layout for specified disk.
#
# Globals:
#   None
# Arguments:
#   Selected disk, a string like "/dev/nvme0n1"
#   Layout file, a path to file that contains instruction for sfdisk command
# Outputs:
#   0 if backup has been created
#   1 if selected disk is not available
#   2 if creating layout failed
#######################################
__disk_createLayout() {
    local -r selected_disk=$1

    #Check disk availability
    __disk_checkDiskAvailability $selected_disk
    if [ $? -ne 0 ]; then
        return 1
    fi

    local -r layout_file=$2

    #Create new disk's layout
    sfdisk $selected_disk < $layout_file 1>/dev/null 2>/dev/null
    if [ $? -ne 0 ]; then
        return 1
    fi
}

#######################################
# Create file system in specified target
#
# Globals:
#   None
# Arguments:
#   Selected target, a string like "/dev/nvme0n1" or "/dev/nvme0n1p3"
#   Desired file system, one of supported string ("fat32", "swap", "btrfs")
# Outputs:
#   None
# Returns:
#   0 if file system has been creted on specified device
#   1 if selected target is not available
#   2 if selected filesystem is not supported
#   3 if file system creation failed
#######################################
__disk_mkfs() {
    local -r selected_target=$1

    #Check target availability
    __disk_checkDiskOrPartitionAvailability $selected_target
    if [ $? -ne 0 ]; then
        return 1
    fi

    local -r filesystem=$2

    case $filesystem in
        fat32) mkfs.fat -F32 "$selected_target" 1>/dev/null 2>/dev/null;;
        swap) mkswap "$selected_target" 1>/dev/null 2>/dev/null;;
        btrfs) mkfs.btrfs -f "$selected_target" 1>/dev/null 2>/dev/null;;
        *) return 2 ;;
    esac

    if [ $? -ne 0 ]; then
        return 3
    fi
}

############################################### API ###############################################

#--------------------------------------------- Layout ---------------------------------------------

#######################################
# Creates a backup file with layout of specified disk
#
# Globals:
#   LOGGER_LEVEL - used by log_xxx functions
# Arguments:
#   Selected disk, a string like "/dev/nvme0n1"
# Outputs:
#   Writes log message with operation result to STDOUT
# Returns:
#   0 if backup file has been created
#   1 if selected disk is not available
#   2 if creating backup file failed
#######################################
disk_backupLayout() {
    local -r selected_disk=$1

    #Check disk availability
    __disk_checkDiskAvailability $selected_disk
    if [ $? -ne 0 ]; then
        log_error "Selected disk [$selected_disk] in not available"
        return 1
    fi

    #Prepare name for backup file
    local -r timestamp=$(date "+%Y.%m.%d-%H.%M.%S.%3N")
    local -r backup_file=$selected_disk_base"_"$timestamp".bak"

    #Backup disk's layout
    __disk_backupLayout $selected_disk $backup_file
    if [ $? -ne 0 ]; then
        log_error "Failed creating backup file of [$selected_disk] disk's layout"
        return 2
    fi

    log_info "Successfully created [$selected_disk] disk's layout backup file [$backup_file]"
}

#######################################
# Creates new layout for specified disk
#
# Globals:
#   LOGGER_LEVEL - used by log_xxx functions
# Arguments:
#   Selected disk, a string like "/dev/nvme0n1"
# Outputs:
#   Writes log message with operation result to STDOUT
# Returns:
#   0 if new disk's layout has been created
#   1 if selected disk is not available
#   2 if creating new disk's layout failed
#######################################
disk_createLayout() {
    local -r selected_disk=$1

    #Check disk availability
    __disk_checkDiskAvailability $selected_disk
    if [ $? -ne 0 ]; then
        log_error "Selected disk [$selected_disk] in not available"
        return 1
    fi

    local -r layout_file=$2

    #Create new disk's layout
    __disk_createLayout $selected_disk $layout_file
    if [ $? -ne 0 ]; then
        log_error "Failed creating new layout for [$selected_disk] disk"
        return 2
    fi

    log_info "Successfully created new layout for [$selected_disk] disk"
}

#######################################
# Backups disk's layout and update to new one.
#
# Globals:
#   LOGGER_LEVEL - used by log_xxx functions
# Arguments:
#   Selected disk, a string like "/dev/nvme0n1"
#   Layout file, a path to file that contains instruction for sfdisk command
# Outputs:
#   Writes log message with operation result to STDOUT
# Returns:
#   0 if disk's layout backup and update has been successfull
#   1 if selected disk is not available
#   2 if creating backup file failed
#   3 if creating new disk's layout failed
#######################################
disk_backupAndUpdateLayout() {
    local -r selected_disk=$1

    #Check disk availability
    __disk_checkDiskAvailability $selected_disk
    if [ $? -ne 0 ]; then
        log_error "Selected disk [$selected_disk] in not available"
        return 1
    fi

    #Backup disk's layout
    disk_backupLayout $selected_disk 1>/dev/null 2>/dev/null
    if [ $? -ne 0 ]; then
        log_error "Failed creating backup file of [$selected_disk] disk's layout"
        return 2
    fi

    local -r layout_file=$2

    #Create new disk's layout
    disk_createLayout $selected_disk $layout_file 1>/dev/null 2>/dev/null
    if [ $? -ne 0 ]; then
        log_error "Failed creating new layout for [$selected_disk] disk"
        return 3
    fi

    log_info "Successfully backuped layout of [$selected_disk] and created new one"
}

#------------------------------------------ File Systems ------------------------------------------

#######################################
# Sets file systems on partitions.
#
# Globals:
#   LOGGER_LEVEL - used by log_xxx functions
# Arguments:
#   Selected disk, a string like "/dev/nvme0n1"
#   Layout file, a path to file that contains instruction for sfdisk command
# Outputs:
#   Writes log message with operation result to STDOUT
# Returns:
#   0 if all file systems on all partitons has been successfully created
#   1 if selected disk is not available
#   2 if amount of partitions on disk do not match amount in layout file specification
#   3 if file system creation failed on at least one partion
#######################################
disk_setPartitionsFileSystems() {
    local -r selected_disk=$1

    #Check disk availability
    __disk_checkDiskAvailability $selected_disk
    if [ $? -ne 0 ]; then
        log_error "Selected disk [$selected_disk] in not available"
        return 1
    fi

    local -r disk_partitions=($(__disk_getDiskPartitions $selected_disk))
    local -r disk_partitions_amount=${#disk_partitions[@]}

    local -r layout_file=$2
    local -r partitions_filesystems=($(__disk_getPartitionsFsFromLayoutFile $layout_file))
    local -r partitions_filesystems_amount=${#partitions_filesystems[@]}

    if [[ $disk_partitions_amount -ne $partitions_filesystems_amount ]]; then
        log_msg="File systems specifications amount($partitions_filesystems_amount) in [$layout_file] file"
        log_msg+=" do not match partitions amount($disk_partitions_amount) on [$selected_disk] disk."
        log_error "$log_msg"
        return 2
    fi

    for idx in "${!disk_partitions[@]}"; do
        local partition=${disk_partitions[$idx]}
        local filesystem=${partitions_filesystems[$idx]}

        __disk_mkfs $partition $filesystem 
        if [ $? -ne 0 ]; then
            log_error "Failed creating [$filesystem] file system on [$partition] target}"
            return 2
        fi
    done

    log_info "Successfully created file systems on all specified partitions"
}

#######################################
# Gets disk's partitions that contains specified file system
#
# Globals:
#   None
# Arguments:
#   Selected disk, a string like "/dev/nvme0n1"
#   File system of patitions that should returned, a string like "btrfs"
# Outputs:
#   Writes list of patitions containing spcified filesystem on disk, a list of string to STDOUT
#######################################
disk_getDiskPartitionsWithSpecifiedFileSystem() {
    local -r selected_disk=$1
    local -r dir_disk=$(dirname $selected_disk)
    local -r specified_filesystem=$2

    lsblk -lnf -o NAME,FSTYPE $selected_disk | grep $specified_filesystem | awk -v d=$dir_disk '{print d"/"$1}'
}

#-------------------------------------------- General ---------------------------------------------

#######################################
# Gets disk's partitions that has specific mount point label in layout file
#
# Globals:
#   None
# Arguments:
#   Selected disk, a string like "/dev/nvme0n1"
#   Layout file, a path to file that contains instruction for sfdisk command
#   Mount point of patition that should be returned, a string like "/mnt/boot"
# Outputs:
#   Writes path of partion with spcified mount point in layout file, a string to STDOUT
# Retruns:
#   0 if successfully returned partition
#   1 if selected disk is not available
#   2 if amount of partitions on disk do not match amount in layout file specification
#   3 if selected mount point do not exist in layout file
#######################################
disk_getDiskPartitonWithSpecifiedMountPointFromLayoutFile() {
    local -r selected_disk=$1

    #Check disk availability
    __disk_checkDiskAvailability $selected_disk
    if [ $? -ne 0 ]; then
        return 1
    fi

    local -r disk_partitions=($(__disk_getDiskPartitions $selected_disk))
    local -r disk_partitions_amount=${#disk_partitions[@]}

    local -r layout_file=$2
    local -r partitions_mount_points=($(__disk_getMountPointsFromLayoutFile $layout_file))
    local -r partitions_mount_points_amount=${#partitions_mount_points[@]}

    if [[ $disk_partitions_amount -ne $partitions_mount_points_amount ]]; then
        return 2
    fi

    local -r selected_mount_point=$3
    for idx in "${!partitions_mount_points[@]}"; do
        local partition=${disk_partitions[$idx]}
        local mount_point=${partitions_mount_points[$idx]}

        if [[ $mount_point == $selected_mount_point ]]; then
            echo $partition
            return 0
        fi
    done

    return 3
}

#######################################
# Display disk devices names.
#
# Globals:
#   LOGGER_LEVEL - used by log_xxx functions
# Arguments:
#   None
# Outputs:
#   Writes lines to STDOUT, where each contains
#   disk NAME TYPE(=disk) SIZE. i.e.:
#   sda     disk 14.5G
#   nvme0n1 disk 100G 
#######################################
disk_displayDisks() {
    log_info "Available disks:"
    __disk_getDisks
}
