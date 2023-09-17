#!/bin/bash

if [ -n "$INTERNET_SH_SOURCED" ]; then return; fi
INTERNET_SH_SOURCED=true

source logger.sh

#######################################
# Checks internet connection.
#
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
# Returns:
#   0 if internet connection works, non-zero otherwise
#######################################
__internet_checkConnection() {
    local -r ping_address="8.8.8.8"
    local -r ping_retries=5

    ping -c ${ping_retries} ${ping_address} 1>/dev/null 2>/dev/null
}

#######################################
# Display internet connection status.
#
# Globals:
#   LOGGER_LEVEL - used by log_XXX functions
# Arguments:
#   None
# Outputs:
#   Writes log message with operation result to STDOUT
# Returns:
#   0 if internet connectio has been established
#   1 if there is no stable internet connection
#######################################
internet_displayConnectionStatus() {
    __internet_checkConnection
    if [ $? -ne 0 ]; then
        log_error "No internet connection"
        return 1
    fi

    log_info "Valid internet connection"
}
