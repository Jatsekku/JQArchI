#!/bin/bash

cd "JQArchI/"

source clock.sh
source defaults.sh
source grub.sh
source initramfs.sh
source keyboard.sh
source locale.sh
source logger.sh
source network.sh
source utils.sh

main_handleLocale() {
    log_debug "Setting locales"
    locale_enableLocales "${DEFAULT_LOCALES[@]}"
    locale_generateLocales
}

main_handleClock() {
    log_debug "Setting clock"
    clock_enableNtp
}

main_handleKeyboard() {
    log_debug "Setting keymap"
    keyboard_setKeymap $DEFAULT_KEYMAP
}

main_handleGrub() {
    log_debug "Install GRUB"

    utils_isBootModeUefi
    local -r boot_mode=$?
    case $boot_mode in
        0) grub_installBios $DEFAULT_DISK ;;
        32) log_error "UEFIx32 is not supported" ;;
        64) grub_installUefi ;;
    esac
}

main_handleNetwork() {
    log_debug "Setting hostname"
    network_setHostName $DEFAULT_HOSTNAME

    log_debug "Setting hosts file"
    network_setHosts
}

main_handleLocale
main_handleClock
main_handleKeyboard

initramfs_mkinitpcioConfigAddModule "btrfs"
initramfs_mkinitcpioGenerate

main_handleGrub
main_handleNetwork
