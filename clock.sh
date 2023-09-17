#!/bin/bash

if [ -n "$CLOCK_SH_SOURCED" ]; then return; fi
CLOCK_SH_SOURCED=true

source logger.sh

#######################################
# Get list of time zones available in system.
#
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Writes available time zones, a list of strings to STDOUT
#######################################
__clock_getTimeZones() {
    timedatectl list-timezones 
}

#######################################
# Checks if time zone is available in system.
#
# Globals:
#   None
# Arguments:
#   Selected time zone, a string
# Outputs:
#   None
# Returns:
#   0 if time zone is available
#   1 if time zone is not available
#######################################
__clock_checkTimeZoneAvailability() {
    local -r selected_timezone=$1
    local -r available_timezones=($(__clock_getTimeZones))

    if  [[ !(${available_timezones[*]} =~ "$selected_timezone") ]]; then
        return 1
    fi
}

#######################################
# Enable NTP.
#
# Globals:
#   LOGGER_LEVEL - used by log_XXX functions
# Arguments:
#   None
# Outputs:
#   Writes log message with operation result to STDOUT
# Returns:
#   0 if NTP has been enabled
#   1 if NTP enabling failed
#######################################
clock_enableNtp() {
    timedatectl set-ntp true 1>/dev/null 2>/dev/null
    if [ $? -ne 0 ]; then
        log_error "Failed to enable NTP"
        return 1
    fi

    log_info "Successfully enable NTP time synchronization"
}

#######################################
# Show current time settngs/status.
#
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Writes time settings/status to STDOUT
#######################################
clock_displayStatus() {
    timedatectl status
}

#######################################
# Display available timezones in columns.
#
# Globals:
#   LOGGER_LEVEL - used by log_xxx function
# Arguments:
#   None
# Outputs:
#   Writes available keymaps to STDOUT
#######################################
clock_displayTimezones() {
    log_info "Available timezones:"
    __clock_getTimeZones | column
}

#######################################
# Set timezone given by user.
#
# Function checks if user-provided timezone
# is available in system and set it if so.
# Function writes log message with operation
# result to STDOUT.
#
# Globals:
#   LOGGER_LEVEL - used by log_xxx functions
# Arguments:
#   Desired timezone, a string
# Outputs:
#   Writes log message with operation result to STDOUT
# Returns:
#   0 if timezone has been set
#   1 if timezone is not available
#   2 if timezone setting failed
#######################################
clock_setTimezone() {
    local -r selected_timezone=$1

    #Check timezone availability
    __clock_checkTimeZoneAvailability $selected_timezone
    if [ $? -ne 0 ]; then
        log_error "Selected timezone [$selected_timezone] is not available"
        return 1
    fi

    #Set timezone
    ln -sf /usr/share/zoneinfo/$selected_timezone /etc/localtime
    if [ $? -ne 0 ]; then
        log_error "Failed to set selected keymap [$selected_timezone]"
        return 2
    fi
}

#######################################
# Synchronize hardware clock with system time.
#
# Function synchronizes hardware clock
# to match the time provided by the system clock 
#
# Globals:
#   LOGGER_LEVEL - used by log_xxx functions
# Arguments:
#   None
# Outputs:
#   Writes log message with operation result to STDOUT
# Returns:
#   0 if hardware clock has been synchronized
#   1 if hardware clock synchronization failed
#######################################
clock_syncHardwareClock() {
    hwclock --systohc 1>/dev/null 2>/dev/null;
    if [ $? -ne 0 ]; then
        log_error "Failed to synchronize hardware clock"
        return 1
    fi

    log_info "Hardware clock has been synchronized"
}
