#!/bin/bash

if [ -n "$INITAMFS_SH_SOURCED" ]; then return; fi
INITAMFS_SH_SOURCED=true

source logger.sh
source __internalUtils.sh

readonly MKINITCPIOCONFIG_FILE_PATH="/etc/mkinitcpio.conf"

__initramfs_mkinitcpioConfigGetModulesLine() {
    grep "^MODULES=" $MKINITCPIOCONFIG_FILE_PATH
}

__initramfs_mkinitcpioConfigGetModules() {
    __initramfs_mkinitcpioConfigGetModulesLine | tr -d "MODULES=(" | tr -d ")"
}

initramfs_mkinitpcioConfigAddModule() {
    local -r selected_modules=$@

    #Check if there is any module to add
    if [[ ${#selected_modules[@]} -eq 0 ]]; then
        return
    fi

    local -r original_modules=($(__initramfs_mkinitcpioConfigGetModules))
    local -r modules_combined="${original_modules[@]} ${selected_modules[@]}"

    local -r original_line="$(__initramfs_mkinitcpioConfigGetModulesLine)"
    local -r replacment_line="MODULES=(${modules_combined[@]})"

    internalUtils_replaceFileLine $MKINITCPIOCONFIG_FILE_PATH "$original_line" "$replacment_line"
    if [ $? -ne 0 ]; then
        log_error "Failed to add modules [$selected_modules]"
    fi

    log_info "Successfully added modules [$selected_modules]"
}

initramfs_mkinitcpioGenerate() {
    mkinitcpio -p linux
}
