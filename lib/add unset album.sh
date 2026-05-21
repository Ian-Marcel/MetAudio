#!/usr/bin/env bash
# Comment:
# Adiciona o valor da tag ALBUM caso ela
# não exista, requerimento: valor da tag
# TITLE

echo "- AUDIOEXIF SWISS-KNIFE - ADD UNSET ALBUM NAME METADATA BASED ON TITLE -------------------------"
CHANGED=0
SKIPPED=0
ERRORS=0
for TRACK in "${TRACKS[@]}"; do
    EXT="${TRACK##*.}"
    EXT="${EXT,,}"                          # lowercase
    TRACK_FOLDER_PATH="${TRACK%/*}"         # ~100% bash version for `dirname` command, not perfect though, for other cases, change delimiter(/) and variable name
    TRACK_FOLDER="${TRACK_FOLDER_PATH##*/}" # ~100% bash version for `basename` command, not perfect though, for other cases, change delimiter(/) and variable name
    # Pula se a extensão não está na lista
    [[ " $EXTENSIONS " == *" $EXT "* ]] || continue
    TITLE=$(exiftool -s3 -Title "$TRACK" 2>/dev/null)
    ALBUM=$(exiftool -s3 -Album "$TRACK" 2>/dev/null)
    ALBUM_FOLDER="${ALBUM//$UNSAFE_TRACK_CHARS_KILLER/_}"
    metatool() {
        case "$EXT" in
        'flac')
            metaflac --set-tag=ALBUM="$TITLE" "$@"
            ;;
        *)
            exiftool -overwrite_original -Album="$TITLE" "$@"
            ;;
        esac
    }
    if [[ -n "$ALBUM" ]]; then
        echo "[SKIP] Álbum já definido: '$ALBUM' → $TRACK"
        # if [ "$TRACK_FOLDER" != "$ALBUM_FOLDER" ]; then
        #     mkdir -p "$TRACK_FOLDER_PATH/$ALBUM_FOLDER"
        #     mv "$TRACK" "$TRACK_FOLDER_PATH/$ALBUM_FOLDER/"
        # fi
        ((SKIPPED++)) || true
        continue
    fi
    if [[ -z "$TITLE" ]]; then
        echo "[WARN] Sem título e sem álbum, ignorando: $TRACK"
        ((ERRORS++)) || true
        continue
    fi
    if metatool "$TRACK" >/dev/null 2>&1; then
        echo "[OK]   Album='$TITLE' → $TRACK"
        # if [ "$TRACK_FOLDER" != "$ALBUM_FOLDER" ]; then
        #     mkdir -p "$TRACK_FOLDER_PATH/$ALBUM_FOLDER"
        #     mv "$TRACK" "$TRACK_FOLDER_PATH/$ALBUM_FOLDER/"
        # fi
        ((CHANGED++)) || true
    else
        echo "[ERR]  Falha ao escrever em: $TRACK"
        ((ERRORS++)) || true
    fi
done
echo ""
echo "Concluído — Alterados: $CHANGED | Ignorados: $SKIPPED | Erros: $ERRORS"
echo '- Done! -------------------------------------------------------'
