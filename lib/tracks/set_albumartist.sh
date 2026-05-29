#!/usr/bin/env bash
# Comment:
# Determines the main artist of each album by surveying ALBUMARTIST tags
# across all tracks. If unset or found in a minority of tracks, falls back
# to ARTIST/ARTISTS tags — using metaflac for FLAC files (which may carry
# multiple ARTIST(S) tags from the multiple_artists operation) and exiftool
# for everything else. Single ARTIST tags holding comma-separated or
# feat.-delimited values are split before counting. The value appearing
# most across all tracks is set as ALBUMARTIST on every track in the album.

echo '- ALBUMARTIST SETTER ------------------------------------------------'

# ── Deduplicate: collect unique album folders ─────────────────────────────
declare -A _SEEN
FOLDERS=()
for TRACK in "${TRACKS[@]}"; do
    FOLDER=$(dirname "$TRACK")
    if [[ -z "${_SEEN[$FOLDER]}" ]]; then
        _SEEN[$FOLDER]=1
        FOLDERS+=("$FOLDER")
    fi
done

# ── Helpers ───────────────────────────────────────────────────────────────

read_album_artist() { # args: <file>
    exiftool -AlbumArtist -s3 "$1" 2>/dev/null
}

split_and_emit() { # args: <raw_value> — splits on comma/feat. and prints one value per line
    local RAW
    RAW=$(echo "$1" | sed -E 's/\s+feat\.?\s+/,/g')
    local HAS_SEPARATOR
    HAS_SEPARATOR=$(echo "$RAW" | grep -o ',')
    if [[ -n "$HAS_SEPARATOR" ]]; then
        IFS=',' read -ra PARTS <<<"$RAW"
        for PART in "${PARTS[@]}"; do
            echo "$PART" | sed 's/^ *//'
        done
    else
        echo "$RAW" | sed 's/^ *//'
    fi
}

read_artist_values() { # args: <file> — prints one artist value per line
    local EXT="${1##*.}"
    EXT="${EXT,,}"
    if [[ "$EXT" == "flac" ]]; then
        local HAS_ARTISTS
        HAS_ARTISTS=$(metaflac --show-tag=ARTISTS "$1" 2>/dev/null)
        if [[ -n "$HAS_ARTISTS" ]]; then
            # multiple_artists already ran: tags are properly split, emit as-is
            metaflac --show-tag=ARTIST --show-tag=ARTISTS "$1" 2>/dev/null |
                sed 's/^[^=]*=//' |
                sed 's/^ *//'
        else
            # Single ARTIST tag may hold comma/feat.-separated values
            local RAW
            RAW=$(metaflac --show-tag=ARTIST "$1" 2>/dev/null | sed 's/^[^=]*=//')
            split_and_emit "$RAW"
        fi
    else
        local RAW
        RAW=$(exiftool -Artist -s3 "$1" 2>/dev/null)
        split_and_emit "$RAW"
    fi
}

set_album_artist() { # args: <file> <artist>
    local EXT="${1##*.}"
    EXT="${EXT,,}"
    if [[ "$EXT" == "flac" ]]; then
        metaflac --remove-tag=ALBUMARTIST "$1"
        metaflac --set-tag=ALBUMARTIST="$2" "$1"
    else
        exiftool -overwrite_original -AlbumArtist="$2" "$1" 2>/dev/null
    fi
}

most_frequent() { # reads lines from stdin, outputs the most frequent one
    sort | uniq -c | sort -rn | head -n1 | sed 's/^ *[0-9]* //'
}

# ── Main loop (one iteration per album folder) ────────────────────────────
for ALBUM_PATH in "${FOLDERS[@]}"; do
    ALBUM_NAME=$(basename "$ALBUM_PATH")
    echo '---'
    echo "Album: $ALBUM_NAME"

    mapfile -t ALBUM_TRACKS < <(find "$ALBUM_PATH" -maxdepth 1 \
        \( -iname "*.flac" -o -iname "*.m4a" -o -iname "*.mp3" \
        -o -iname "*.ogg" -o -iname "*.opus" -o -iname "*.wma" \) | sort)

    TOTAL=${#ALBUM_TRACKS[@]}
    if ((TOTAL == 0)); then
        echo "[WARN] $ALBUM_NAME — no audio files found at depth 1, skipping."
        continue
    fi

    # ── Step 1: Survey ALBUMARTIST across all tracks ──────────────────────
    ALBUMARTIST_VALUES=()
    for TRACK in "${ALBUM_TRACKS[@]}"; do
        VALUE=$(read_album_artist "$TRACK")
        [[ -n "$VALUE" ]] && ALBUMARTIST_VALUES+=("$VALUE")
    done
    ALBUMARTIST_COUNT=${#ALBUMARTIST_VALUES[@]}

    # ── Step 2: Determine main artist ─────────────────────────────────────
    if ((ALBUMARTIST_COUNT * 2 > TOTAL)); then
        MAIN_ARTIST=$(printf '%s\n' "${ALBUMARTIST_VALUES[@]}" | most_frequent)
        echo "AlbumArtist found in $ALBUMARTIST_COUNT/$TOTAL tracks. Using: $MAIN_ARTIST"
    else
        echo "AlbumArtist found in $ALBUMARTIST_COUNT/$TOTAL tracks (minority/none). Searching Artist tags..."

        ARTIST_VALUES=()
        for TRACK in "${ALBUM_TRACKS[@]}"; do
            while IFS= read -r VALUE; do
                [[ -n "$VALUE" ]] && ARTIST_VALUES+=("$VALUE")
            done < <(read_artist_values "$TRACK")
        done

        if ((${#ARTIST_VALUES[@]} == 0)); then
            echo "[WARN] $ALBUM_NAME — no Artist tags found either, skipping."
            continue
        fi

        MAIN_ARTIST=$(printf '%s\n' "${ARTIST_VALUES[@]}" | most_frequent)
        echo "Main artist determined from Artist tags: $MAIN_ARTIST"
    fi

    # ── Step 3: Set ALBUMARTIST on all tracks ─────────────────────────────
    for TRACK in "${ALBUM_TRACKS[@]}"; do
        TRACK_FILE=$(basename "$TRACK")
        CURRENT=$(read_album_artist "$TRACK")
        if [[ "$CURRENT" == "$MAIN_ARTIST" ]]; then
            echo "[SKIP] $TRACK_FILE — AlbumArtist already correct."
            continue
        fi
        echo "  Setting AlbumArtist='$MAIN_ARTIST' → $TRACK_FILE"
        set_album_artist "$TRACK" "$MAIN_ARTIST"
    done
done

echo '- Done! -------------------------------------------------------------'
