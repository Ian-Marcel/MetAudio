#!/usr/bin/env bash
# Comment:
# Add to the album's folder name it's type:
# (S)Single, (EP)Extended Play or (FL)Full Length

echo '- ALBUM TYPE CLASSIFIER -------------------------------------------------'
# ── Deduplicate: collect unique parent folders ────────────────────────────────
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
CLASSIFIED_RE='^(S|Single|EP|Extended Play|FL|Full Length) - '

change_folder_name() { # args: <current-path> <parent-path> <folder-name> <type>
    local TRACK_PATH=$1 PARENT=$2 FOLDER=$3 TYPE=$4
    local NEW_NAME="$TYPE - $FOLDER"
    printf '  %s  →  %s\n' "$FOLDER" "$NEW_NAME"
    mv -- "$TRACK_PATH" "$PARENT/$NEW_NAME"
}

# ── Main loop (one iteration per folder) ─────────────────────────────────────
for TRACK_PATH in "${FOLDERS[@]}"; do
    TRACK_FOLDER=$(basename "$TRACK_PATH")
    PARENT=$(dirname "$TRACK_PATH")

    # Already classified?
    if echo "$TRACK_FOLDER" | grep -Eqm1 "$CLASSIFIED_RE"; then
        echo "[SKIP] $TRACK_FOLDER is already classified."
        continue
    fi

    # Strip any pre-existing non-classification prefix  (e.g. "2024 - AlbumName" → "AlbumName")
    STRIPPED=$(echo "$TRACK_FOLDER" | sed 's/^[^-]*- //')
    if [ "$STRIPPED" != "$TRACK_FOLDER" ]; then
        mv -- "$TRACK_PATH" "$PARENT/$STRIPPED"
        TRACK_FOLDER="$STRIPPED"
        TRACK_PATH="$PARENT/$TRACK_FOLDER"
    fi

    COUNT=$(find "$TRACK_PATH" -maxdepth 1 \
        \( -iname "*.flac" -o -iname "*.m4a" \) | wc -l)

    if [[ "$TRACK_PATH" != $ORIGIN ]]; then
        if ((COUNT >= 1 && COUNT <= 2)); then
            change_folder_name "$TRACK_PATH" "$PARENT" "$TRACK_FOLDER" "Single"
        elif ((COUNT >= 3 && COUNT <= 7)); then
            change_folder_name "$TRACK_PATH" "$PARENT" "$TRACK_FOLDER" "Extended Play"
        elif ((COUNT > 7)); then
            change_folder_name "$TRACK_PATH" "$PARENT" "$TRACK_FOLDER" "Full Length"
        else
            echo "[WARN] $TRACK_FOLDER — no audio files found at depth 1, skipping."
        fi
    fi
done

echo '- Done! -----------------------------------------------------------------'
