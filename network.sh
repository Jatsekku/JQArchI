#!/bin/bash

source logger.sh

readonly HOSTS_FILE_PATH="/etc/hosts"

if [ -n "$NETWORK_SH_SOURCED" ]; then return; fi
NETWORK_SH_SOURCED=true

__network_getHostName() {
    hostnamectl hostname
}


network_setHostName() {
    local -r selected_hostname=$1

    hostnamectl set-hostname $selected_hostname
    if [ $? -ne 0 ]; then
        log_error "Failed to set hostname [$selected_hostname]"
        return 1
    fi
}

network_setHosts() {
    local -r hostname=$(__network_getHostName)
    content="127.0.0.1\tlocalhost\n"
    content+="::1\t\tlocalhost\n"
    content+="127.0.1.1\t$hostname.localdomain\t$hostname\n"

    printf "$content" >> $HOSTS_FILE_PATH
    if [ $? -ne 0 ]; then
        log_error "Failed to correctly create [$HOSTS_FILE_PATH] file"
        return 1
    fi
}
