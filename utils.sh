#!/usr/bin/env bash

set -e

prompt_choice() {
    local message choices
    message=$1
    choices=("${@:2}")

    while true; do
        read -r -p "$message [${choices[*]}]: " REPLY
        for choice in "${choices[@]}"; do
            if [ "${choice,,}" == "${REPLY,,}" ]; then
                echo "$choice"
                return 0
            fi
        done
    done
}
