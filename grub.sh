#!/bin/bash

if [ -n "$GRUB_SH_SOURCED" ]; then return; fi
GRUB_SH_SOURCED=true

source disk.sh
source logger.sh

readonly GRUB_CONFIG_FILE_PATH="/boot/grub/grub.cfg"

#######################################
# Installs and config grub in UEFI mode.
#
# Globals:
#   LOGGER_LEVEL - used by log_xxx functions
#   GRUB_CONFIG_FILE_PATH - path where grub config will be stored
# Arguments:
#   None
# Outputs:
#   Writes log message with operation result to STDOUT
# Returns: 
#   0 if grub has been installed and configured
#   2 if grub installation failed
#   3 if generating grub's configuration failed
#######################################
grub_installUefi() {
    #Install grub
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
    if [ $? -ne 0 ]; then
        log_error "Grub installation failed"
        return 2
    fi

    #Generate grub's config
    grub-mkconfig -o $GRUB_CONFIG_FILE_PATH
    if [ $? -ne 0 ]; then
        log_error "Generating grub's configuration failed"
        return 3
    fi

    log_info "Grub has been installed and configured successfully"
}

#######################################
# Installs and config grub in BIOS mode.
#
# Globals:
#   LOGGER_LEVEL - used by log_xxx functions
#   GRUB_CONFIG_FILE_PATH - path where grub config will be stored
# Arguments:
#   None
# Outputs:
#   Writes log message with operation result to STDOUT
# Returns: 
#   0 if grub has been installed and configured
#   1 if selected disk is not available
#   2 if grub installation failed
#   3 if generating grub's configuration failed
#######################################
grub_installBios() {
    local -r selected_disk=$1
    
    #Check disk availability
    __disk_checkDiskAvailability $selected_disk
    if [ $? -ne 0 ]; then
        log_error "Selected disk [$selected_disk] in not available"
        return 1
    fi

    grub-install $selected_disk
    if [ $? -ne 0 ]; then
        log_error "Grub installation failed"
        return 2
    fi

    grub-mkconfig -o $GRUB_CONFIG_FILE_PATH
    if [ $? -ne 0 ]; then
        log_error "Generating grub's configuration failed"
        return 3
    fi

    log_info "Grub has been installed and configured successfully"
}
