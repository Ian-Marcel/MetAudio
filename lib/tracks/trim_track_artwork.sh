#!/usr/bin/env bash
# Comment:
# Trim disproporcional artwork's/coverart's ratio
# to match 1:1, which is the standart.

echo "- AUDIOEXIF SWISS-KNIFE - TRIM TRACK ARTWORK/COVERART TO MATCH 1:1 RATIO  -------------------------"
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
    metatool() {
        case "$EXTENSION" in
        'flac')
            metaflac --import-picture-from="$TRACK_COVER_ART" "$@"
            ;;
        *)
            exiftool -overwrite_original "-CoverArt<=$TRACK_COVER_ART" "$@"
            ;;
        esac
    }
    printf "  [1/3] Title found: %s\n" "$TRACK_TITLE"
    printf "  [2/3] Extracting cover art -> original.%s\n" "$TRACK_COVER_ART"
    exiftool -CoverArt -b "$TRACK" >"original.$TRACK_COVER_ART"
    ART_DIMS=$(ffprobe -v error -select_streams v:0 \
        -show_entries stream=width,height -of csv=p=0 "original.$TRACK_COVER_ART" 2>/dev/null)
    ART_W="${ART_DIMS%%,*}"
    ART_H="${ART_DIMS##*,}"
    if [[ "$ART_W" -eq "$ART_H" ]]; then
        printf "  [SKIP] Cover art already 1:1 (%sx%s). Skipping track.\n" "$ART_W" "$ART_H"
        continue
    fi
    printf "  [3/3] Cropping to 1:1 (%sx%s -> %sx%s) -> %s\n" "$ART_W" "$ART_H" "$ART_H" "$ART_H" "$TRACK_COVER_ART"
    ffmpeg -i "original.$TRACK_COVER_ART" -vf "crop=ih:ih:(iw-ih)/2:0" -frames:v 1 -update 1 "$TRACK_COVER_ART" -y &>/dev/null
    printf "  [OK] Writing cover art back into: %s\n" "$TRACK"
    metatool "$TRACK" 1>/dev/null
    printf "[DONE] %s\n" "$TRACK"
done
printf "Cleaning up residues. \n"
cd "$CURRENT_DIR"
rm -rf "$WORK_DIR"
echo '- Done! -------------------------------------------------------'
