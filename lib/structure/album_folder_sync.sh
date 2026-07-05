#!/usr/bin/env bash
# Comment:
# Renames each album folder to match its ALBUM tag (read from the album's
# first track). Preserves any albums_sort_by_track_count.sh classification
# prefix (Single/Extended Play/Full Length -) already present on the folder
# name, so this operation stays compatible whether sort_album_type has
# already run or runs afterward.

echo '- ALBUM FOLDER NAME SYNC --------------------------------------------------'

# ── Deduplicate: collect unique album folders ─────────────────────────────────
unset _SEEN
declare -A _SEEN
FOLDERS=()
for TRACK in "${TRACKS[@]}"; do
    FOLDER=$(dirname "$TRACK")
    if [[ -z "${_SEEN[$FOLDER]}" ]]; then
        _SEEN[$FOLDER]=1
        FOLDERS+=("$FOLDER")
    fi
done

# ── Helpers ───────────────────────────────────────────────────────────────────
# Same classification prefix pattern used by albums_sort_by_track_count.sh
CLASSIFIED_RE='^(S|Single|EP|Extended Play|FL|Full Length) - '

get_album_tag() { # args: <file>
    exiftool -Album -s3 "$1" 2>/dev/null
}

sanitize_name() { # args: <name> — replaces every UNSAFE_FILE_CHARS_KILLER char with '_'
    printf '%s' "$1" | sed -E "s/${UNSAFE_FILE_CHARS_KILLER}/_/g"
}

normalize() { # args: <name> — case-insensitive comparison key (NOT fuzzy matching)
    printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

# ── Main loop (one iteration per album folder) ────────────────────────────────
for ALBUM_PATH in "${FOLDERS[@]}"; do
    ALBUM_FOLDER=$(basename "$ALBUM_PATH")
    PARENT=$(dirname "$ALBUM_PATH")

    FIRST_TRACK=$(find "$ALBUM_PATH" -maxdepth 1 \
        \( -iname "*.flac" -o -iname "*.m4a" -o -iname "*.mp3" \
        -o -iname "*.ogg" -o -iname "*.opus" -o -iname "*.wma" \) |
        sort | head -n1)

    if [[ -z "$FIRST_TRACK" ]]; then
        echo "[WARN] $ALBUM_FOLDER — no audio files found at depth 1, skipping."
        continue
    fi

    ALBUM_TAG=$(get_album_tag "$FIRST_TRACK")

    if [[ -z "$ALBUM_TAG" ]]; then
        echo "[WARN] $ALBUM_FOLDER — Album tag is not set, skipping."
        continue
    fi

    ALBUM_TAG=$(sanitize_name "$ALBUM_TAG")

    # Strip off any existing sort_album_type classification prefix so it is
    # neither lost nor duplicated, and isn't part of the name being compared.
    PREFIX=""
    COMPARE_NAME="$ALBUM_FOLDER"
    if [[ "$ALBUM_FOLDER" =~ $CLASSIFIED_RE ]]; then
        PREFIX="${BASH_REMATCH[0]}"
        COMPARE_NAME="${ALBUM_FOLDER#"$PREFIX"}"
    fi

    if [[ "$(normalize "$COMPARE_NAME")" == "$(normalize "$ALBUM_TAG")" ]]; then
        echo "[SKIP] $ALBUM_FOLDER already matches Album tag '$ALBUM_TAG'."
        continue
    fi

    NEW_NAME="${PREFIX}${ALBUM_TAG}"
    DEST="$PARENT/$NEW_NAME"

    if [[ "$ALBUM_PATH" == "$DEST" ]]; then
        echo "[SKIP] $ALBUM_FOLDER already matches Album tag '$ALBUM_TAG'."
        continue
    fi

    if [[ -e "$DEST" ]]; then
        echo "[WARN] $DEST already exists, skipping $ALBUM_FOLDER."
        continue
    fi

    printf '  %s  →  %s\n' "$ALBUM_FOLDER" "$NEW_NAME"
    mv -- "$ALBUM_PATH" "$DEST"
done

echo '- Done! -----------------------------------------------------------------'
