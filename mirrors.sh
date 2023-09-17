#!/bin/bash

if [ -n "$MIRRORS_SH_SOURCED" ]; then return; fi
MIRRORS_SH_SOURCED=true

source logger.sh

#######################################
# Gets list of countries supported by reflector.
#
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Writes list of countries, a list of strings, delimeted by "," to STDOUT
#######################################
__mirrors_getCountries() {
    reflector --list-countries | tail -n +3 | awk -F'  ' '{printf $1 ","}'
}

#######################################
# Checks if country is supported by reflector.
#
# Globals:
#   None
# Arguments:
#   Selected country, a string
# Outputs:
#   None
# Returns:
#   0 if country is available, non-zero otherwise
#######################################
__mirros_checkCountryAvailability() {
    local -r selected_country=$1
    IFS=","
    local available_countries=($(__mirrors_getCountries))
    unset IFS

    if [[ !(${available_countries[*]} =~ "$selected_country") ]]
    then
        return 1
    fi
}

#######################################
# Finds list of mirrors and saves it to given file
#
# Function finds mirror list for specfied country
# with specified lookback synchronization period.
# Mirros sorted by speed will be written under specified file
#
# Globals:
#   None
# Arguments:
#   Country for which mirrors has to be established, a string
#   Lookback synchronization period from now, a integer (given in hours)
#   Path for file where result should be written, a string
# Outputs:
#   None
#######################################
__mirrors_findAndSave() {
    local -r selected_country=$1
    local -r synchronization_time=$2
    local -r result_file=$3

    reflector -c $selected_country -a $synchronization_time --sort rate --save $3 1>/dev/null 2>/dev/null
}

#######################################
# Display countries supported by reflector.
#
# Globals:
#   LOGGER_LEVEL - used by log_xxx functions
# Arguments:
#   None
# Outputs:
#  Writes countries supported by reflector to STDOUT
#######################################
mirrors_displayCountries() {
    log_info "Reflector's supported countries:"
    __mirrors_getCountries | tr ',' '\n' | column
}

#######################################
# Updates mirrors list.
#
# Globals:
#   LOGGER_LEVEL - used by log_xxx functions
# Arguments:
#   Country for which mirrors has to be established, a string
#   Lookback synchronization period from now, a integer (given in hours)
# Outputs:
#   Writes log message with operation result to STDOUT
# Returns:
#   0 if mirrors list has been updated and saved
#   1 if selected country is not supported by reflector
#   2 if mirrors list generating failed
#######################################
mirrors_update() {
    local -r selected_country=$1

    #Check country availability
    __mirros_checkCountryAvailability $selected_country
    if [ $? -ne 0 ]; then
        log_error "Selected country [$selected_country] is not supported by reflector"
        return 1
    fi

    local -r synchronization_time=$2
    local -r result_file="/etc/pacman.d/mirrorlist"

    __mirrors_findAndSave $selected_country $synchronization_time $result_file
    if [ $? -ne 0 ]; then
        log_msg="Failed to generate mirrors list with specified parameters:\n"
        log_msg+="Country: [$selected_country]\n"
        log_msg+="Lookback synchronization period: [-$synchronization_time]"
        log_error "$log_msg"
        return 2
    fi

    log_info "Successfully updated mirrors list and saved result to [$result_file] file"
}
