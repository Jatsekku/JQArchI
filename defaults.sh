#!/bin/bash

if [ -n "$DEFAULTS_SH_SOURCED" ]; then return; fi
DEFAULTS_SH_SOURCED=true

readonly DEFAULT_KEYMAP="pl"
readonly DEFAULT_LOCALES=("pl_PL.UTF-8 UTF-8" "en_US.UTF-8 UTF-8")
readonly DEFAULT_COUNTRY="Poland"
readonly DEFAULT_TIMEZONE="Europe/Warsaw"
readonly DEFAULT_MIRRORS_LOOKBACK_SYNC_TIME=6
readonly DEFAULT_DISK="/dev/vda"
readonly DEFAULT_PARTITION_SCHEME_FILE="partionSchemes/1G_efi-8G_swap-REST.sfdisk"
readonly DEFAULT_BTRFS_LAYOUT_FILE="btrfsLayouts/snapper.btrfs"
readonly DEFAULT_HOSTNAME="Anemone"