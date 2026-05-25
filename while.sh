#!/usr/bin/env bash

# OPTIONS:
#   --tracks-operation= | -t=opt1,opt2,... @required(conflicts with --structure-operation/-s)
#   --structure-operation= | -s=opt1,opt2,... @required(conflicts with --tracks-operation/-t)
#   --destination="directory" | -d="directory"  @optional
# EXAMPLES:
#   audioxif --tracks-operation=opt1,opt2 <origin_directory>
#   audioxif <origin_directory> --structure-operation=opt1,opt2 --destination=<destination_directory>
#   audioxif -d=<destination_directory> <origin_directory> -t=opt1,opt2
#   audioxif <origin_directory> -s=opt1,opt2
#   audioxif --tracks-operation=\
##  opt1,\
##  opt2,\
##  opt3

ORIGIN='.'
ARGS=$(echo $@ | tr -s ' ')
read -ra ARGS_DIGESTER <<<"$ARGS"
ARGD_INDEX=0
while [ -n "${ARGS_DIGESTER[$ARGD_INDEX]}" ]; do
    case "${ARGS_DIGESTER[$ARGD_INDEX]}" in
    -s=* | --structure-operation=*)
        if [ "${TRACKS_OPS:-}" ]; then
            echo "ERROR: tracks operation was declared! Tracks and structure operations cannot run together."
            exit 1
        fi
        IFS=',' read -ra STRUCTURE_OPS <<<"$(echo "${ARGS_DIGESTER[$ARGD_INDEX]}" | sed 's/^[^=]*=//')"
        ;;
    -t=* | --tracks-operation=*)
        if [ "${STRUCTURE_OPS:-}" ]; then
            echo "ERROR: structure operation was declared! Tracks and structure operations cannot run together."
            exit 1
        fi
        IFS=',' read -ra TRACKS_OPS <<<"$(echo "${ARGS_DIGESTER[$ARGD_INDEX]}" | sed 's/^[^=]*=//')"
        ;;
    -d | --destination)
        ((ARGD_INDEX++))
        if [ -d "${ARGS_DIGESTER[$ARGD_INDEX]}" ]; then
            DESTINATION_PATH="${ARGS_DIGESTER[$ARGD_INDEX]}"
        else
            case "${ARGS_DIGESTER[$ARGD_INDEX]}" in
            -c | --copy)
                echo "ERROR: -c/--copy argument must be declared before -d/--destination or after -d/--destination path!"
                ;;
            -m | --move)
                echo "ERROR: -m/--move argument must be declared before -d/--destination or after -d/--destination path!"
                ;;
            *)
                echo "ERROR: -d/--destination argument was declared without a path!"
                ;;
            esac
            exit
        fi
        DESTINATION_TRANSPORT_METHOD=${DESTINATION_TRANSPORT_METHOD:-'move'}
        ;;
    -m | --move) # Default destination transport method, is a meta-argument, only purpose is for clarification in scripts.
        DESTINATION_TRANSPORT_METHOD='move'
        ;;
    -c | --copy)
        DESTINATION_TRANSPORT_METHOD='copy'
        ;;
    *)
        if [ -d "${ARGS_DIGESTER[$ARGD_INDEX]}" -a "$ORIGIN" = '.' ]; then
            ORIGIN="${ARGS_DIGESTER[$ARGD_INDEX]}"
        else
            echo -e "ERROR: Additonal unrecognized argument was declared!
                \rSee audioxif --help for guidance."
            exit 1
        fi
        ;;
    esac
    ((ARGD_INDEX++))
done
if ! [ "${STRUCTURE_OPS:-}" -o "${TRACKS_OPS:-}" ]; then
    echo "No operation declared!"
    exit
fi
ORIGIN=$(realpath $ORIGIN)
echo "ORIGIN is: $ORIGIN"
if [ "${DESTINATION_PATH:-}" ]; then
    DESTINATION_PATH=$(realpath $DESTINATION_PATH)
    echo "DESTINATION is: $DESTINATION_PATH"
    echo "DESTINATION transport method is: $DESTINATION_TRANSPORT_METHOD"
fi
