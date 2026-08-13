#!/usr/bin/env bash
# Comment:
# Trim disproporcional artwork's/coverart's ratio
# to match 1:1, which is the standart.

upsert_cover_art() {
    case "$EXTENSION" in
    'flac')
        metaflac --remove --block-type=PICTURE "$@" &&
            metaflac --import-picture-from="$TRACK_COVER_ART" "$@"
        ;;
    *)
        exiftool -overwrite_original "-CoverArt<=$TRACK_COVER_ART" "$@"
        ;;
    esac
}

echo "- TRIM TRACK ARTWORK/COVERART TO MATCH 1:1 RATIO  -------------------------"
CURRENT_DIR="$PWD"
WORK_DIR="/tmp/operation-$RANDOM$RANDOM$RANDOM"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"
for TRACK in "${TRACKS[@]}"; do
    EXTENSION="${TRACK##*.}"                              # Pega a extensão do arquivo.
    EXTENSION="${EXTENSION,,}"                            # Deixa ela em caixa alta.
    [[ " $EXTENSIONS " == *" $EXTENSION "* ]] || continue # Pula se a extensão não está na lista.
    printf "\n[>>] Processing: %s\n" "$TRACK"
    TRACK_TITLE=$(exiftool -s3 -Title "$TRACK" 2>/dev/null)                                     # Pega o titulo da música.
    printf -v TRACK_COVER_ART "CoverArt - %s.jpg" "${TRACK_TITLE//$UNSAFE_FILE_CHARS_KILLER/_}" # Gera o nome do CoverArt da música baseado no titulo dela.
    echo "$TRACK_COVER_ART"
    printf "  [1/3] Title found: %s\n" "$TRACK_TITLE"
    printf "  [2/3] Extracting cover art -> original.%s\n" "$TRACK_COVER_ART"
    if [ "$EXTENSION" == 'flac' ] && [ -n "$(metaflac --list --block-type=PICTURE "$TRACK")" ]; then
        metaflac --export-picture-to=./original."$TRACK_COVER_ART" "$TRACK"
    elif [ -n "$(exiftool -s3 -CoverArt $TRACK)" ]; then
        exiftool -CoverArt -b "$TRACK" >./"original.$TRACK_COVER_ART"
    elif [ -n "$(exiftool -s3 -Picture $TRACK)" ]; then
        exiftool -Picture -b "$TRACK" >./"original.$TRACK_COVER_ART"
    fi
    ART_DIMS=$(ffprobe -v error -select_streams v:0 \
        -show_entries stream=width,height -of csv=p=0 "original.$TRACK_COVER_ART" 2>/dev/null)
    ART_W="${ART_DIMS%%,*}"
    ART_H="${ART_DIMS##*,}"
    if [[ "$ART_W" -eq "$ART_H" ]]; then
        printf "  [SKIP] Cover art already 1:1 (%sx%s). Skipping track.\n" "$ART_W" "$ART_H"
        continue
    fi
    ART_S=$((ART_W < ART_H ? ART_W : ART_H)) # if width(ART_W) is lesser than height(ART_H) then ART_S = width, otherwise ART_S = height
    printf "  [3/3] Cropping to 1:1 (%sx%s -> %sx%s) -> %s\n" "$ART_W" "$ART_H" "$ART_S" "$ART_S" "$TRACK_COVER_ART"
    # Crop a centered 1:1 square using the smaller input dimension (works for both landscape and portrait);
    # Output size becomes min(iw,ih) x min(iw,ih), centered via x/y offsets.
    ffmpeg -i "original.$TRACK_COVER_ART" \
        -vf 'crop=w=min(iw\,ih):h=min(iw\,ih):x=(iw-min(iw\,ih))/2:y=(ih-min(iw\,ih))/2' \
        -frames:v 1 -y "$TRACK_COVER_ART" >/dev/null 2>&1
    printf "  [OK] Writing cover art back into: %s\n" "$TRACK"
    upsert_cover_art "$TRACK" 1>/dev/null
    printf "[DONE] %s\n" "$TRACK"
done
printf "Cleaning up residues. \n"
cd "$CURRENT_DIR"
rm -rf "$WORK_DIR"
echo '- Done! -------------------------------------------------------'
