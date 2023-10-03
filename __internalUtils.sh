#!/bin/bash

if [ -n "$__INTERNALUTILS_SH_SOURCED" ]; then return; fi
__INTERNALUTILS_SH_SOURCED=true

#######################################
# Replace line in file.
#
# Globals:
#   None
# Arguments:
#   Path to file that will be modified, a string
#   Original line that should be replaced, a string
#   Desired line replacement, a string
# Outputs:
#   None
# Returns:
#   0 if modification was successfull
#   1 if file do not exist
#   2 if specified original line is empty string
#   3 if file modification failed
#######################################
internalUtils_replaceFileLine() {
    local -r file_to_edit=$1
    local -r original_line=$2
    local -r replacment_line=$3

    #Check if file exist
    if [ ! -f $file_to_edit ]; then
        return 1
    fi

    #Check if original line string is not empty
    if [[ $original_line == "" ]]; then
        return 2
    fi

    #Edit line in file
    sed -i "s/$original_line/$replacment_line/" $file_to_edit

    #Check if modification finished without error
    if [ $? -ne 0 ]; then
        return 3
    fi
}
