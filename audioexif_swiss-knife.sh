#!/usr/bin/env bash

TARGET=${1:-.}
if ! [ -d "$TARGET" ]; then
    echo "[ERROR]: '$TARGET' is not a folder/directory."
    exit 1
fi
TARGET=$(realpath "$TARGET")
UNSAFE_FILE_CHARS_KILLER='[\/\\:*?"<>|]' # Identifica `chars` não aceitos em arquivos para que possam ser substituidos.
EXTENSIONS="mp3 flac m4a ogg opus wma"
TRACKS=()
for EXTENSION in $EXTENSIONS; do
    mapfile -t -O "${#TRACKS[@]}" TRACKS < <(find "$TARGET" -iname "*.$EXTENSION" | sort)
done

echo "AUDIOEXIF SWISS-KNIFE"

# Comment:
# Make a single ARTIST that contains more than one
# artist in a multiple ARTISTS for the 'coadjuvants artists',
# intended for Navidrome use.
source "./lib/multiple artists.sh"

# Comment:
# Read the Track number exif data from the audio file
# and adds it to start of the a audio file's name.
source "./lib/tracks position in album.sh"

# Comment:
# Adiciona o valor da tag ALBUM caso ela
# não exista, requerimento: valor da tag
# TITLE
source "./lib/add unset album.sh"

# Comment:
# Trim disproporcional artwork's/coverart's ratio
# to 1:1, which is the standart.
source "./lib/trim track artwork.sh"
