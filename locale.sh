#!/bin/bash

if [ -n "$LOCALE_SH_SOURCED" ]; then return; fi
LOCALE_SH_SOURCED=true

source logger.sh

readonly LOCALE_FILE_PATH="/etc/locale.gen"

#######################################
# Get list of all locale available in system.
#
# Globals:
#   LOCALE_FILE_PATH - path to locale.gen file
# Arguments:
#   None
# Outputs:
#   Writes all available locale, a list of strings to STDOUT
#######################################
__locale_getAllLocale() {
    #Skip lines:
    # - starting with "# " (hash and withespace)
    # - starting with "#$" (hash and EOL)
    grep -v -e "^\(#\s\)" -e "^#$" $LOCALE_FILE_PATH | tr -d '#'
}

#######################################
# Get list of system's enabled locale.
#
# Globals:
#   LOCALE_FILE_PATH - path to locale.gen file
# Arguments:
#   None
# Outputs:
#   Writes system's enabled locale, a list of strings to STDOUT
#######################################
__locale_getEnabledlocale() {
    #Match lines starting with any non-whitespace character other than #
    grep -E "^[^#\s].*" $LOCALE_FILE_PATH
}

#######################################
# Get list of system's disabled locale.
#
# Globals:
#   LOCALE_FILE_PATH - path to locale.gen file
# Arguments:
#   None
# Outputs:
#   Writes system's disabled locale, a list of strings to STDOUT
#######################################
__locale_getDisabledlocale() {
    #Match lines starting with # and non-whitespace character
    grep -E "^#\S" $LOCALE_FILE_PATH | td -d '#'
}

#######################################
# Checks if locale is available in system.
#
# Globals:
#   None
# Arguments:
#   Selected locale, a string
# Outputs:
#   None
# Returns:
#   0 if locale is available, non-zero otherwise
#######################################
__locale_checkLocaleAvailability() {
    local -r selected_locale=$1

    local -r available_locale=($(__locale_getAllLocale))
    #Check if given string is empty
    if [[ $selected_locale == "" ]]; then
        return 1
    fi

    if [[ !(${available_locale[*]} =~ "$selected_locale") ]]
    then
        return 1
    fi
}

__locale_replaceLine() {
    local -r original_line=$1
    local -r replacment_line=$2

    if [[ $original_line != "" && replacment_line != "" ]]; then
        sed -i "s/$original_line/$replacment_line/" $LOCALE_FILE_PATH
    fi
}

__locale_enableSingleEntry() {
    local -r selected_locale=$1

    #Check locale availability
    __locale_checkLocaleAvailability $selected_locale
    if [ $? -ne 0 ]; then
        return 1
    fi

    __locale_replaceLine "#$selected_locale" "$selected_locale"
        if [ $? -ne 0 ]; then
        return 2
    fi
}

__locale_disableSingleEntry() {
    local -r selected_locale=$1

    #Check locale availability
    __locale_checkLocaleAvailability $selected_locale
    if [ $? -ne 0 ]; then
        return 1
    fi

    __locale_replaceLine "$selected_locale" "#$selected_locale"
    if [ $? -ne 0 ]; then
        return 2
    fi
}

locale_enableLocales() {
    local valid_locales
    local invalid_locales

    #Check locales availability
    for selected_locale in "$@"
    do
        __locale_checkLocaleAvailability "$selected_locale"
        if [ $? -ne 0 ]; then
            invalid_locales+=("$selected_locale")
        else
            valid_locales+=("$selected_locale")
        fi
    done

    #Report invalid locales
    if [[ ${#invalid_locales[@]} -ne 0 ]]; then
        local log_msg="Below listed locales are unavailable:"
        for invalid_locale in "${invalid_locales[@]}"
        do
            log_msg+="\n$invalid_locale"
        done
        log_warning "$log_msg"
    fi

    #Check if valid locales list is empty
    if [[ ${#valid_locales[@]} -eq 0 ]]; then
        log_error "No valid locales"
        return 1
    fi

    #Report valid locales
    local log_msg="Below listed locales are available:"
    for valid_locale in "${valid_locales[@]}"
    do
        log_msg+="\n$valid_locale"
    done
    log_info "$log_msg"

    #Apply valid locales
    local valid_locales_enabled_counter=0
    for valid_locale in "${valid_locales[@]}"
    do
        __locale_enableSingleEntry $valid_locale
        if [ $? -ne 0 ]; then
            log_error "Failed to enable [$valid_locale]"
        else
            valid_locales_enabled_counter=$((valid_locales_enabled_counter+1))
        fi
    done

    #Report final operation status
    if [[ $valid_locales_enabled_counter -ne ${#valid_locales[@]} ]]; then
        log_error "Failed to enabled all of available locales"
        return 2
    fi
    
    log_info "Successfully enabled all available locales"
}

locale_generateLocales() {
    locale-gen
}

#######################################
# Display all available locale in columns.
#
# Globals:
#   LOGGER_LEVEL - used by log_xxx function
# Arguments:
#   None
# Outputs:
#   Writes available locale to STDOUT
#######################################
locale_displayAllLocale() {
    log_info "Available locale:"
    __locale_getAllLocale | column
}
