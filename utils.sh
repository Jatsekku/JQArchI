#!/bin/bash

if [ -n "$UTILS_SH_SOURCED" ]; then return; fi
UTILS_SH_SOURCED=true

source logger.sh

__utils_determineMicroCode() {
    local -r CPU=$(grep vendor_id /proc/cpuinfo)

    if [[ "$CPU" == *"AuthenticAMD"* ]]; then
        echo "amd-ucode"
    else
        echo "intel-ucode"
    fi
}

__utils_kernelSelectionGuard() {
    local -r selected_kernel=$1
    local -r available_kernels=("linux" "linux-hardened" "linux-lts" "linux-zen")

    if [[ !(${available_kernels[*]} =~ "$selected_kernel") ]]
    then
        log_error "Selected kernel ($selected_kernel) is not available"
        return 1
    fi
}

utils_runPacstrap() {
    # Kernel
    local -r kernel=$1
    __utils_kernelSelectionGuard $kernel
    if [ $? -ne 0 ]; then
        return 1
    fi

    #Kernel headers
    local -r kernel_headers=$kernel"-headers"

    #Microcode
    local -r microcode=$(__utils_determineMicroCode)

    #Essentials
    local -r essentials=("base" "linux-firmware" "grub" "efibootmgr" "reflector" "snapper")

    #Packages combined
    local -r packages=("$kernel" "$kernel_headers" "$microcode" ${essentials[@]})

    local log_msg="Following packages will be installed:\n"
    log_msg+="$(echo ${packages[@]} | tr -s ' ' '\n')"
    log_info "$log_msg"

    local -r installation_directory="/mnt"
    pacstrap $installation_directory ${packages[@]}
}

utils_runGenfstab() {
    local -r installation_directory="/mnt"
    
    genfstab -U $installation_directory >> /mnt/etc/fstab
}

utils_chroot() {
    local -r installation_directory="/mnt"

    arch-chroot $installation_directory
}

#######################################
# Check if boot mode is UEFI and which one if so
#
# Globals:
#   LOGGER_LEVEL - used by log_xxx functions
# Arguments:
#   None
# Outputs:
#   Writes log message with operation result to STDOUT
# Retruns:
#   0 if boot mode is not UEFI
#   32 if boot mode is UEFI x32
#   64 if boot mode is UEFI x64
#######################################
utils_isBootModeUefi() {
    cat /sys/firmware/efi/fw_platform_size 1>/dev/null 2>/dev/null
    if [ $? -ne 0 ]; then
        log_debug "Platform is not using UEFI boot mode"
        return 0
    fi

    local -r efi_fw_platform_size=$(cat /sys/firmware/efi/fw_platform_size)

    if [[ $efi_fw_platform_size == "64" ]]; then
        log_debug "Platform is using UEFIx64 boot mode"
        return 64
    fi

    if [[ $efi_fw_platform_size == "32" ]]; then
        log_debug "Platform is using UEFIx32 boot mode"
        return 32
    fi

}
