# Metadata Operations (`-m` / `--metadata-operation`)

These operations edit the tags stored *inside* your audio files.

| Operation | What it does |
|---|---|
| `multiple_artists` | **FLAC only.** Splits one `ARTIST` tag with multiple artists (separated by commas or "feat.") into a main `ARTIST` plus separate `ARTISTS` entries for the rest. Sets the first artist as `ALBUMARTIST`. Made for Navidrome compatibility. |
| `set_album_name` | Copies the `TITLE` tag into `ALBUM` — but only if `ALBUM` is empty. Leaves files that already have an `ALBUM` tag untouched. |
| `trim_artwork` | Center-crops embedded cover art that isn't square (1:1) so it becomes square. Skips art that's already square. |
| `set_album_artist` | Looks at the `AlbumArtist` tag across every track in an album folder. If it's missing or only on a few tracks, it falls back to the `Artist`/`Artists` tags instead (splitting up combined names first). Whichever artist name shows up most often gets written as `AlbumArtist` on every track in the album. |

Run `metaudio -m=help` (or `--metadata-operation=help`) to see this same information from the tool itself.

---
[← Back to README](../README.md)
