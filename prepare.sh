#!/bin/bash

readonly REPO_URL="https://github.com/Jatsekku/JQArchI.git"
readonly ACTIVE_BRANCH="devel"

__install_git() {
    pacman -Sy --noconfirm git
}

__clone_repo() {
    git clone $REPO_URL
}

__checkout_activeBranch() {
    local -r branch=$1

    git checkout $branch
}

__enter_repo() {
    local -r directory=$(basename $REPO_URL)

    cd ${directory%.*}
}

__install_git
__clone_repo
__enter_repo
__checkout_activeBranch $ACTIVE_BRANCH
