# Structure Operations (`-s` / `--structure-operation`)

These operations change file names and folder organization — not the tags themselves.

| Operation | What it does |
|---|---|
| `track_positioner` | Reads the track number from a file's metadata and adds it to the front of the filename (e.g. `3 - Song Title.flac`). Skips files already numbered. Warns and skips files with no track number to read. |
| `sort_album_type` | Adds a label to the front of each album folder's name, based on how many tracks it has: `Single -` (1–2 tracks), `Extended Play -` (3–7 tracks), or `Full Length -` (8+ tracks). Skips folders that already have a label. Removes any other prefix (like a leading year) first. |
| `artist_base_structure` | Reads the `AlbumArtist` tag from an album's first track and moves that album into an `Artist/Album` folder structure. Skips albums with no `AlbumArtist` tag, and skips (with a warning) if the destination folder already exists. |
| `album_folder_sync` | Reads the `Album` tag from an album's first track and renames the folder to match it (case-insensitive), keeping any `sort_album_type` label already on the folder. Skips albums with no `Album` tag, folders that already match, and cases where the target name is already taken. |

Run `metaudio -s=help` (or `--structure-operation=help`) to see this same information from the tool itself.

---
[← Back to README](../README.md)
