#!/bin/bash

if [ -n "$KEYBOARD_SH_SOURCED" ]; then return; fi
KEYBOARD_SH_SOURCED=true

source logger.sh

#######################################
# Get list of keymaps available in system.
#
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Writes available keymaps, a list of strings to STDOUT
#######################################
__keyboard_getKeymaps() {
    localectl list-keymaps
}

#######################################
# Checks if keymap is available in system.
#
# Globals:
#   None
# Arguments:
#   Selected keymap, a string
# Outputs:
#   None
# Returns:
#   0 if keymap is available, non-zero otherwise
#######################################
__keyboard_checkKeymapAvailability() {
    local -r selected_keymap=$1
    local -r available_keymaps=($(__keyboard_getKeymaps))

    if [[ !(${available_keymaps[*]} =~ "$selected_keymap") ]]
    then
        return 1
    fi
}

#######################################
# Display available keymaps in columns.
#
# Globals:
#   LOGGER_LEVEL - used by log_xxx function
# Arguments:
#   None
# Outputs:
#   Writes available keymaps to STDOUT
#######################################
keyobard_displayKeymaps() {
    log_info "Available keymaps:"
    __keyboard_getKeymaps | column
}

#######################################
# Set keymap given by user.
#
# Function checks if user-provided keymap
# is available in system and set it if so.
# Function writes log message with operation
# result to STDOUT.
#
# Globals:
#   LOGGER_LEVEL - used by log_xxx functions
# Arguments:
#   Desired keymap, a string
# Outputs:
#   Writes log message with operation result to STDOUT.
# Returns:
#   0 if keymap has been set
#   1 if keymap is not available
#   2 if keymap loading failed
#######################################
keyboard_setKeymap() {
    local selected_keymap=$1

    #Check keymap availability
    __keyboard_checkKeymapAvailability $selected_keymap
    if [ $? -ne 0 ]; then
        log_error "Selected keymap [$selected_keymap] is not available"
        return 1
    fi

    #Set keymap
    localectl set-keymap --no-convert $selected_keymap
    if [ $? -ne 0 ]; then
        log_error "Failed to load selected keymap [$selected_keymap]"
        return 2
    fi

    log_info "Successfully loaded selected keymap [$selected_keymap]"
}
