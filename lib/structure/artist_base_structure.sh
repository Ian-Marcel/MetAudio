#!/usr/bin/env bash
# Comment:
# Reads the ALBUMARTIST tag from the first track of each album folder
# and organizes albums into an Artist/Album structure under the origin directory.

echo '- ARTIST STRUCTURE ORGANIZER --------------------------------------------'

# ── Deduplicate: collect unique album folders ─────────────────────────────────
unset _SEEN
declare -A _SEEN
FOLDERS=()
for TRACK in "${TRACKS[@]}"; do
    FOLDER=$(dirname "$TRACK")
    if [[ -z "${_SEEN[$FOLDER]:-}" ]]; then
        _SEEN[$FOLDER]=1
        FOLDERS+=("$FOLDER")
    fi
done

# ── Helpers ───────────────────────────────────────────────────────────────────
get_album_artist() { # args: <file> <file-extension>
    case "$2" in
    'flac')
        metaflac --show-tag=ALBUMARTIST "$1" | sed 's/^[^=]*=//' | sed '1q'
        ;;
    *)
        exiftool -AlbumArtist -s3 "$1" 2>/dev/null
        ;;
    esac
}

sanitize_name() { # args: <name> — strips path separators and control characters
    printf '%s' "$1" | tr -d '/' | tr -d '\000-\037'
}

normalize() { # args: <name> — case-insensitive comparison key (NOT fuzzy matching)
    printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

# ── Main loop (one iteration per album folder) ────────────────────────────────
for ALBUM_PATH in "${FOLDERS[@]}"; do
    ALBUM_NAME=$(basename "$ALBUM_PATH")

    FIRST_TRACK=$(find "$ALBUM_PATH" -maxdepth 1 \
        \( -iname "*.flac" -o -iname "*.m4a" \) | sort | head -n1)

    if [[ -z "$FIRST_TRACK" ]]; then
        echo "[WARN] $ALBUM_NAME — no audio files found at depth 1, skipping."
        continue
    fi

    ARTIST=$(get_album_artist "$FIRST_TRACK" "${FIRST_TRACK##*.}")

    if [[ -z "$ARTIST" ]]; then
        echo "[WARN] $ALBUM_NAME — AlbumArtist tag is not set, skipping."
        continue
    fi

    ARTIST=$(sanitize_name "$ARTIST")
    ARTIST_DIR="$ORIGIN/$ARTIST"
    DEST="$ARTIST_DIR/$ALBUM_NAME"

    # Check up to 2 levels above the album folder for a directory already
    # named after the artist, rather than only checking the exact
    # $ORIGIN/$ARTIST/$ALBUM_NAME path.
    PARENT_1="$(dirname "$ALBUM_PATH")"
    PARENT_1_NAME="$(basename "$PARENT_1")"
    PARENT_2="$(dirname "$PARENT_1")"
    PARENT_2_NAME="$(basename "$PARENT_2")"

    if [[ "$(normalize "$PARENT_1_NAME")" == "$(normalize "$ARTIST")" ]]; then
        echo "[SKIP] $ALBUM_NAME is already under an artist-named folder ($PARENT_1_NAME, 1 level up)."
        continue
    fi

    if [[ "$(normalize "$PARENT_2_NAME")" == "$(normalize "$ARTIST")" ]]; then
        echo "[SKIP] $ALBUM_NAME is already under an artist-named folder ($PARENT_2_NAME, 2 levels up)."
        continue
    fi

    if [[ -e "$DEST" ]]; then
        echo "[WARN] $DEST already exists, skipping $ALBUM_NAME."
        continue
    fi

    mkdir -p "$ARTIST_DIR"
    printf '  %s  →  %s/%s\n' "$ALBUM_NAME" "$ARTIST" "$ALBUM_NAME"
    mv -- "$ALBUM_PATH" "$DEST"
done

echo '- Done! -----------------------------------------------------------------'
