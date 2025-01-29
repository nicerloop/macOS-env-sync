#!/bin/sh
set -e

usage() {
    exit_code=${1:-0}
    echo "Usage: $0 [-n notify] [-w watch]"
    exit "$exit_code"
}

error() {
    message=${1:-"Unknown error"}
    echo "$message" >&2
    usage 1
}

NOTIFY=false
WATCH=false

while getopts ":hnw" opt; do
    case $opt in
    \?) error "Invalid option: $OPTARG" ;;
    :) error "Option -$OPTARG requires an argument." ;;
    h) usage ;;
    n) NOTIFY=true ;;
    w) WATCH=true ;;
    esac
done
shift $((OPTIND - 1))

if [ $# -eq 0 ]; then
    set -- "$HOME/.zshrc"
fi

NAMES=$(grep '^[:space:]*export' "$@" | cut -d '=' -f 1 | cut -d ' ' -f 2 | sort -u)
VALUES=$(env | grep "$NAMES" | sort -u -t '=' -k 1)
for VALUE in $VALUES; do
    NAME=$(echo "$VALUE" | cut -d '=' -f 1)
    VALUE=$(echo "$VALUE" | cut -d '=' -f 2)
    if [ "$VALUE" != "$(launchctl getenv "$NAME")" ]; then
        launchctl setenv "$NAME" "$VALUE"
        UPDATED=true
    fi
done
$UPDATED && $NOTIFY && terminal-notifier -message 'Environment variables updated'
$WATCH && fswatch -1 "$@" >/dev/null
