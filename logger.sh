#!/bin/bash

if [ -n "$LOGGER_SH_SOURCED" ]; then return; fi
LOGGER_SH_SOURCED=true

readonly LOGGER_ERROR=1
readonly LOGGER_WARNING=2
readonly LOGGER_INFO=3
readonly LOGGER_DEBUG=4

readonly LOGGER_BOLD='\e[1m'
readonly LOGGER_RED='\e[91m'
readonly LOGGER_GREEN='\e[92m'
readonly LOGGER_BLUE='\e[34m'  
readonly LOGGER_YELLOW='\e[93m'
readonly LOGGER_RESET='\e[0m'

LOGGER_LEVEL=$LOGGER_DEBUG

#######################################
# Display error message (red bold text).
#
# Log is displayed if global variable LOGGER_LEVEL
# is greater or equal to LOGGER_ERROR
#
# Globals:
#   LOGGER_LEVEL
# Arguments:
#   Message content, a string that should be displayed
# Outputs:
#   Writes formated log message to STDOUT
#######################################
log_error() {
    if [ $LOGGER_LEVEL -ge $LOGGER_ERROR ]; then
        echo -e "${LOGGER_BOLD}${LOGGER_RED}[ • ] $1${LOGGER_RESET}"
    fi
}

#######################################
# Display warning message (yellow bold text).
#
# Log is displayed if global variable LOGGER_LEVEL
# is greater or equal to LOGGER_WARNING
#
# Globals:
#   LOGGER_LEVEL
# Arguments:
#   Message content, a string that should be displayed
# Outputs:
#   Writes formated log message to STDOUT
#######################################
log_warning() {
    if [ $LOGGER_LEVEL -ge $LOGGER_WARNING ]; then
        echo -e "${LOGGER_BOLD}${LOGGER_YELLOW}[ • ] $1${LOGGER_RESET}"
    fi
}

#######################################
# Display info message (green bold text).
#
# Log is displayed if global variable LOGGER_LEVEL
# is greater or equal to LOGGER_INFO
#
# Globals:
#   LOGGER_LEVEL
# Arguments:
#   Message content, a string that should be displayed
# Outputs:
#   Writes formated log message to STDOUT
#######################################
log_info() {
    if [ $LOGGER_LEVEL -ge $LOGGER_INFO ]; then
        echo -e "${LOGGER_BOLD}${LOGGER_GREEN}[ • ] $1${LOGGER_RESET}"
    fi
}

#######################################
# Display info message (white bold text).
#
# Log is displayed if global variable LOGGER_LEVEL
# is greater or equal to LOGGER_DEBUG
#
# Globals:
#   LOGGER_LEVEL
# Arguments:
#   Message content, a string that should be displayed
# Outputs:
#   Writes formated log message to STDOUT
#######################################
log_debug() {
    if [ $LOGGER_LEVEL -ge $LOGGER_DEBUG ]; then
        echo -e "${LOGGER_BOLD}[ • ] $1${LOGGER_RESET}"
    fi
}
