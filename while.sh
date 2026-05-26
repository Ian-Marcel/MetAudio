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

NO_PROMPTS='false'
ORIGIN='.'
INDEX=0
ARGS=$(echo $@ | tr -s ' ')
read -ra ARGS_DIGESTER <<<"$ARGS"
while [ -n "${ARGS_DIGESTER[$INDEX]}" ]; do
    ARG=${ARGS_DIGESTER[$INDEX]}
    case "$ARG" in
    -s=* | --structure-operation=*)
        if [ "${OPS_ARRAY:-}" ]; then
            echo "ERROR: tracks operation was declared first! Tracks and structure operations cannot run together."
            exit 1
        fi
        IFS=',' read -ra OPS_ARRAY <<<"$(echo "$ARG" | sed 's/^[^=]*=//')"
        ;;
    -t=* | --tracks-operation=*)
        if [ "${OPS_ARRAY:-}" ]; then
            echo "ERROR: structure operation was declared first! Tracks and structure operations cannot run together."
            exit 1
        fi
        IFS=',' read -ra OPS_ARRAY <<<"$(echo "$ARG" | sed 's/^[^=]*=//')"
        ;;
    -d | --destination)
        ((INDEX++))
        POST_DEST_DIGEST_INDEX=$INDEX # LATER: Discover a way of enabling entering --copy and --move args between --destination and --destination's path
        if [ -d "$ARG" ]; then
            DESTINATION_PATH="$ARG"
            DESTINATION_TRANSPORT_METHOD=${DESTINATION_TRANSPORT_METHOD:-'move'}
        else
            case "$ARG" in
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
        ;;
    -m | --move) # Default destination transport method, is a meta-argument, only purpose is for clarification in scripts.
        DESTINATION_TRANSPORT_METHOD='move'
        ;;
    -c | --copy)
        DESTINATION_TRANSPORT_METHOD='copy'
        ;;
    -y | --assume-yes)
        NO_PROMPTS='true'
        ;;
    *)
        if [ -d "$ARG" -a "$ORIGIN" = '.' ]; then
            ORIGIN="$ARG"
        else
            echo -e "ERROR: Additonal unrecognized argument was declared!
                \rSee audioxif --help for guidance."
            exit 1
        fi
        ;;
    esac
    ((INDEX++))
done
if ! [ "${OPS_ARRAY:-}" ]; then
    echo "No operation declared!"
    exit
fi
INDEX=0
ORIGIN=$(realpath $ORIGIN)
echo "ORIGIN is: $ORIGIN"
if [ "${DESTINATION_PATH:-}" ]; then
    DESTINATION_PATH=$(realpath $DESTINATION_PATH)
    echo "DESTINATION is: $DESTINATION_PATH"
    echo "DESTINATION transport method is: $DESTINATION_TRANSPORT_METHOD"
fi
if [ "$NO_PROMPTS" == 'false' ]; then
    while [[ true ]]; do
        echo "Is info above correct? [Y/n]"
        read -rp 'Answer: ' CORASWR
        case "$CORASWR" in
        [yY] | [yY]es)
            echo Proceeding...
            break
            ;;
        [nN] | [nN]o)
            echo Exiting...
            exit 0
            ;;
        *)
            echo "Answer with y/yes or n/no."
            ;;
        esac

    done
fi

# OPTS
