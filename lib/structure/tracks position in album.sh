#!/usr/bin/env bash
# Comment:
# Make a single ARTIST that contains more than one
# artist in a multiple ARTISTS for the 'coadjuvants artists',
# intended for Navidrome use.

echo "- AUDIOEXIF SWISS-KNIFE - TRACKS POSITION IN ALBUM -------------------------"
MESSAGE_OCURRANCE=0
for TRACK in "${TRACKS[@]}"; do
    FILE="${TRACK##*/}"                                   # Name of the file containing the track.
    EXTENSION="${FILE##*.}"                               # Type of file (extension).
    EXTENSION="${EXTENSION,,}"                            # Type of file (extension). Lowercased
    [[ " $EXTENSIONS " == *" $EXTENSION "* ]] || continue # Pula se a extensão não está na lista.
    TITLE=$(exiftool -s3 -Title "$TRACK" 2>/dev/null)     #  [From metadata] Name of the track's Title.
    ALBUM=$(exiftool -s3 -Album "$TRACK" 2>/dev/null)     #  [From metadata] Name of the track's Album.
    ALBUM_FOLDER="${ALBUM/$UNSAFE_FILE_CHARS_KILLER/_}"
    TRACK_NUMBER=$(exiftool -s3 -Tracknumber "$TRACK")
    if [ $MESSAGE_OCURRANCE == 0 ]; then
        echo "[INFO]: ABOUT TO EDIT ALBUM: $ALBUM"
    fi
    if [ -z "$TRACK_NUMBER" ]; then
        echo -e "[ERROR]: Tracknumber couldn't be retrieved! \nMaybe this is a Single? \nSkipping..."
        continue
    fi
    if ! printf "$FILE" | grep --quiet -E "^0?$TRACK_NUMBER - "; then
        mv "$TRACK" "$TARGET_DIR/$TRACK_NUMBER - $FILE"
        echo "[INFO]: $FILE RENAMED TO $TRACK_NUMBER - $FILE"
    else
        echo "[WARN]: TRACK IS ALREADY NUMBERED: $FILE"
    fi
    MESSAGE_OCURRANCE=1
    continue
done
echo '- Done! -------------------------------------------------------'
