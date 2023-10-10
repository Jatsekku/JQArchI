#!/bin/bash

readonly SUDOERS_FILE_PATH=
user_addUser() {
    for user in "$@"; do
        useradd -mG wheel $user 
    done
}

#TODO
user_enableWheelGroup() {

}