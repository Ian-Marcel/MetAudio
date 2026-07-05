#!/usr/bin/env bash
# Comment:
# Ensures each track lives in a folder matching its own Album tag, checking
# every track individually rather than assuming a folder's first track
# speaks for the whole folder.
#
# - Tracks sitting directly in $ORIGIN (no containing album folder) are
#   moved into a newly created (or already-existing) folder named after
#   their own Album tag. $ORIGIN itself is never renamed or moved.
# - For tracks inside an existing non-origin folder: if every track in that
#   folder shares the same Album tag (case-insensitive), the whole folder is
#   renamed to match (preserving any albums_sort_by_track_count.sh
#   classification prefix already present). If tracks in the folder disagree
#   on Album tag, the folder itself is left alone and each mismatched track
#   is moved individually into a sibling folder (same parent) named after
#   its own Album tag.

echo '- ALBUM FOLDER / TRACK SYNC ------------------------------------------------'

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

move_track() { # args: <track> <target_dir> — moves a single file, never overwrites
    local TRACK=$1 TARGET_DIR=$2
    local BASENAME
    BASENAME=$(basename "$TRACK")
    mkdir -p "$TARGET_DIR"
    if [[ -e "$TARGET_DIR/$BASENAME" ]]; then
        echo "[WARN] $TARGET_DIR/$BASENAME already exists, skipping $TRACK."
        return
    fi
    printf '  %s  →  %s/%s\n' "$TRACK" "$TARGET_DIR" "$BASENAME"
    mv -- "$TRACK" "$TARGET_DIR/$BASENAME"
}

# ── Deduplicate: collect unique containing folders (including $ORIGIN itself
#    when tracks sit directly inside it) ────────────────────────────────────
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

# ── Main loop (one iteration per unique folder) ───────────────────────────────
for FOLDER in "${FOLDERS[@]}"; do
    mapfile -t FOLDER_TRACKS < <(find "$FOLDER" -maxdepth 1 \
        \( -iname "*.flac" -o -iname "*.m4a" -o -iname "*.mp3" \
        -o -iname "*.ogg" -o -iname "*.opus" -o -iname "*.wma" \) | sort)

    if ((${#FOLDER_TRACKS[@]} == 0)); then
        echo "[WARN] $FOLDER — no audio files found at depth 1, skipping."
        continue
    fi

    # ── Case A: tracks sit directly in $ORIGIN — $ORIGIN can never be
    #    renamed/moved, so each track is individually filed into its own
    #    Album-tag-named folder instead. ─────────────────────────────────────
    if [[ "$FOLDER" == "$ORIGIN" ]]; then
        for TRACK in "${FOLDER_TRACKS[@]}"; do
            ALBUM_TAG=$(get_album_tag "$TRACK")
            if [[ -z "$ALBUM_TAG" ]]; then
                echo "[WARN] $(basename "$TRACK") — no Album tag, skipping."
                continue
            fi
            ALBUM_TAG=$(sanitize_name "$ALBUM_TAG")
            TARGET_DIR="$ORIGIN/$ALBUM_TAG"
            move_track "$TRACK" "$TARGET_DIR"
        done
        continue
    fi

    # ── Non-origin folder: survey every track's Album tag ──────────────────
    VALID_TRACKS=()
    VALID_TAGS=()
    for TRACK in "${FOLDER_TRACKS[@]}"; do
        TAG=$(get_album_tag "$TRACK")
        if [[ -z "$TAG" ]]; then
            echo "[WARN] $(basename "$TRACK") — no Album tag, skipping this track."
            continue
        fi
        VALID_TRACKS+=("$TRACK")
        VALID_TAGS+=("$TAG")
    done

    if ((${#VALID_TAGS[@]} == 0)); then
        echo "[WARN] $(basename "$FOLDER") — no tracks with an Album tag found, skipping."
        continue
    fi

    UNIQUE_NORM_COUNT=$(printf '%s\n' "${VALID_TAGS[@]}" | while IFS= read -r T; do normalize "$T"; done | sort -u | wc -l)

    PARENT=$(dirname "$FOLDER")
    FOLDER_NAME=$(basename "$FOLDER")

    # Strip off any existing sort_album_type classification prefix so it is
    # neither lost nor duplicated, and isn't part of the name being compared.
    PREFIX=""
    COMPARE_NAME="$FOLDER_NAME"
    if [[ "$FOLDER_NAME" =~ $CLASSIFIED_RE ]]; then
        PREFIX="${BASH_REMATCH[0]}"
        COMPARE_NAME="${FOLDER_NAME#"$PREFIX"}"
    fi

    if ((UNIQUE_NORM_COUNT == 1)); then
        # ── Case B: homogeneous folder — safe to rename the whole folder ───
        ALBUM_TAG=$(sanitize_name "${VALID_TAGS[0]}")

        if [[ "$(normalize "$COMPARE_NAME")" == "$(normalize "$ALBUM_TAG")" ]]; then
            echo "[SKIP] $FOLDER_NAME already matches Album tag '$ALBUM_TAG'."
            continue
        fi

        NEW_NAME="${PREFIX}${ALBUM_TAG}"
        DEST="$PARENT/$NEW_NAME"

        if [[ -e "$DEST" ]]; then
            echo "[WARN] $DEST already exists, skipping $FOLDER_NAME."
            continue
        fi

        printf '  %s  →  %s\n' "$FOLDER_NAME" "$NEW_NAME"
        mv -- "$FOLDER" "$DEST"
    else
        # ── Case C: heterogeneous folder — leave the folder itself alone,
        #    move each mismatched track individually to a sibling folder
        #    named after its own Album tag. ────────────────────────────────
        echo "[INFO] $FOLDER_NAME — tracks disagree on Album tag, splitting individually."
        for INDEX in "${!VALID_TRACKS[@]}"; do
            TRACK="${VALID_TRACKS[$INDEX]}"
            ALBUM_TAG=$(sanitize_name "${VALID_TAGS[$INDEX]}")
            if [[ "$(normalize "$COMPARE_NAME")" == "$(normalize "$ALBUM_TAG")" ]]; then
                echo "[SKIP] $(basename "$TRACK") — already in a folder matching its Album tag."
                continue
            fi
            TARGET_DIR="$PARENT/$ALBUM_TAG"
            move_track "$TRACK" "$TARGET_DIR"
        done
    fi
done

echo '- Done! -----------------------------------------------------------------'
